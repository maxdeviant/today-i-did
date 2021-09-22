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

  issue <- lift $ Issue.findIssue linearClient (IssueId "API-379")

  Console.logShow issue
