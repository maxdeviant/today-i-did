module Main where

import Prelude

import Control.Monad.Except (except, lift, runExceptT)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Dotenv as DotEnv
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console as Console
import GitHub.Client as GitHub
import Linear.Client as Linear
import Linear.Issue (IssueId(..))
import Linear.Issue as Issue
import Node.Process (lookupEnv)

main :: Effect Unit
main = launchAff_ $ runExceptT do
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

  issue <- lift $ Issue.findIssue linearClient (IssueId "API-767")

  Console.logShow issue
