module Main where

import Prelude

import Control.Monad.Except (except, lift, runExceptT)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Dotenv as DotEnv
import Effect (Effect)
import Effect.Aff (Error, runAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console as Console
import GitHub.Client as GitHub
import Linear.Client as Linear
import Node.Process (lookupEnv)
import TodayIDid.DailyReport as DailyReport

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

  dailyReport <- lift $ DailyReport.fromFile "TODAY.md"
  processedReport <- lift $ DailyReport.fillOut githubClient linearClient dailyReport

  Console.logShow processedReport
