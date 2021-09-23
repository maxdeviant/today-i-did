module TodayIDid.DailyReport where

import Prelude

import Control.Monad.Except (ExceptT, lift, runExceptT)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Either as Either
import Data.Int as Int
import Data.Interpolate (i)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.String (Pattern(..))
import Data.String (joinWith, split) as String
import Data.String.Utils (lines, words) as String
import Data.Traversable (traverse)
import Effect.Aff (Aff)
import GitHub.Client (GitHubClient)
import GitHub.PullRequest (PullRequest(..))
import GitHub.PullRequest as PullRequest
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

fillOut :: GitHubClient -> DailyReport -> Aff (Either String DailyReport)
fillOut githubClient (DailyReport dailyReport) = runExceptT do
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
                let
                  prLink :: String
                  prLink = i "[PR " pullRequest.number "](" word ")"
                pure $ i "(" prLink ")"
              Nothing -> pure word
        )
    pure $ processedWords # String.joinWith " "
