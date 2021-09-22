module Main where

import Prelude

import Control.Monad.Except (except, lift, runExceptT)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Int as Int
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..))
import Data.String as String
import Dotenv as DotEnv
import Effect (Effect)
import Effect.Aff (Error, runAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console as Console
import GitHub.Client as GitHub
import GitHub.PullRequest as PullRequest
import Linear.Client as Linear
import Linear.Issue (IssueId(..))
import Linear.Issue as Issue
import Node.Process (lookupEnv)

parsePullRequestUrl :: String -> Either String { owner :: String, repo :: String, pullNumber :: Int }
parsePullRequestUrl url =
  case String.split (Pattern "/") url # Array.drop 2 of
    [ "github.com", owner, repo, "pull", rawPullNumber ] ->
      case Int.fromString rawPullNumber of
        Just pullNumber -> Right { owner, repo, pullNumber }
        Nothing -> Left $ "Not a GitHub PR URL: " <> url
    _ -> Left $ "Not a GitHub PR URL: " <> url

logError :: forall a. Either Error (Either String a) -> Effect Unit
logError = case _ of
  Left error -> Console.logShow error
  Right success -> case success of
    Left error -> Console.log error
    Right _ -> pure unit

main :: Effect Unit
main = runAff_ logError $ runExceptT do
  _ <- lift DotEnv.loadFile

  linearApiKey <- do
    apiKey <- liftEffect $ lookupEnv "LINEAR_API_KEY"
    except $ case apiKey of
      Just apiKey' -> Right $ Linear.ApiKey apiKey'
      Nothing -> Left "LINEAR_API_KEY not set."
  linearClient <- liftEffect $ Linear.mkClient linearApiKey

  githubToken <- do
    token <- liftEffect $ lookupEnv "GITHUB_TOKEN"
    except $ case token of
      Just token' -> Right $ GitHub.PersonalAccessToken token'
      Nothing -> Left "GITHUB_TOKEN not set."
  githubClient <- liftEffect $ GitHub.mkClient githubToken

  parseResult <- except $ parsePullRequestUrl "https://github.com/workos-inc/workos-node/pull/470"
  pullRequest <- lift $ PullRequest.findPullRequest githubClient parseResult.owner parseResult.repo parseResult.pullNumber
  Console.logShow pullRequest

  prComments <- lift $ PullRequest.listComments githubClient parseResult.owner parseResult.repo parseResult.pullNumber
  Console.logShow prComments

  issue <- lift $ Issue.findIssue linearClient (IssueId "SDK-262")
  Console.logShow issue
