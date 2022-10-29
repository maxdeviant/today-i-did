module TodayIDid.DailyReport where

import Prelude

import Control.Monad.Except (ExceptT, lift, runExceptT)
import Data.Array as Array
import Data.Array.NonEmpty as NonEmptyArray
import Data.Either (Either(..))
import Data.Either as Either
import Data.Int as Int
import Data.Interpolate (i)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.String (Pattern(..))
import Data.String (joinWith, split) as String
import Data.String.Regex as Regex
import Data.String.Regex.Flags (RegexFlags(..), noFlags)
import Data.String.Utils (lines, words) as String
import Data.Traversable (traverse)
import Effect.Aff (Aff)
import GitHub.Client (GitHubClient)
import GitHub.PullRequest (PullRequest(..), Comment)
import GitHub.PullRequest as PullRequest
import Linear.Client (LinearClient)
import Linear.Issue (Issue(..), IssueId(..))
import Linear.Issue as Issue
import Node.Encoding (Encoding(..))
import Node.FS.Aff as Fs

newtype DailyReport = DailyReport String

derive instance newtypeDailyReport :: Newtype DailyReport _

derive newtype instance showDailyReport :: Show DailyReport

fromFile :: String -> Aff DailyReport
fromFile = map DailyReport <<< Fs.readTextFile UTF8

parsePullRequestUrl :: String -> Either String { owner :: String, repo :: String, pullNumber :: Int }
parsePullRequestUrl url =
  case String.split (Pattern "/") url # Array.drop 2 of
    [ "github.com", owner, repo, "pull", rawPullNumber ] ->
      case Int.fromString rawPullNumber of
        Just pullNumber -> Right { owner, repo, pullNumber }
        Nothing -> Left $ "Not a GitHub PR URL: " <> url
    _ -> Left $ "Not a GitHub PR URL: " <> url

parseLinearIssueUrl :: String -> Either String { id :: IssueId }
parseLinearIssueUrl url =
  case String.split (Pattern "/") url # Array.drop 2 of
    [ "linear.app", _team, "issue", id, _slug ] -> Right { id: IssueId id }
    _ -> Left $ "Not a Linear issue URL: " <> url

isFromLinearBot :: Comment -> Boolean
isFromLinearBot = _.user >>> _.login >>> (==) "linear-app[bot]"

findMentionedLinearIssues :: Array Comment -> Array IssueId
findMentionedLinearIssues comments =
  comments
    # Array.filter isFromLinearBot
    # Array.mapMaybe (_.body >>> findIssuesInBody)
    # Array.concatMap NonEmptyArray.toArray
    # Array.catMaybes
    # Array.mapMaybe (parseLinearIssueUrl >>> Either.hush >>> map _.id)
  where
  findIssuesInBody body = do
    let flags = noFlags # (\(RegexFlags flags') -> RegexFlags flags' { global = true, multiline = true })
    pattern <- Either.hush $ Regex.regex "https:\\/\\/linear\\.app\\/.*\\/issue\\/[-A-Z0-9]*\\/[-a-z0-9]*" flags
    Regex.match pattern body

fillOut :: GitHubClient -> LinearClient -> DailyReport -> Aff (Either String DailyReport)
fillOut githubClient linearClient (DailyReport dailyReport) = runExceptT do
  processedLines <- String.lines dailyReport # traverse processLine
  pure $ DailyReport $ String.joinWith "\n" processedLines
  where
  processLine :: String -> ExceptT String Aff String
  processLine line = do
    processedWords <-
      line # String.words # traverse
        ( \word -> do
            case Either.hush $ parsePullRequestUrl word of
              Just { owner, repo, pullNumber } -> do
                (PullRequest pullRequest) <- lift $ PullRequest.findPullRequest githubClient owner repo pullNumber
                prComments <- lift $ PullRequest.listComments githubClient owner repo pullNumber
                linearIssues <- lift $ prComments # findMentionedLinearIssues # traverse (Issue.findIssue linearClient)
                let
                  prLink :: String
                  prLink = i "[PR " pullRequest.number "](" word ")"

                  linearIssueLinks :: Array String
                  linearIssueLinks = linearIssues # map \(Issue { identifier: (IssueId id), url }) -> i "[" id "](" url ")"

                  allLinks = linearIssueLinks `Array.snoc` prLink

                pure $ i "(" (allLinks # String.joinWith ", ") ")"
              Nothing -> pure word
        )
    pure $ processedWords # String.joinWith " "
