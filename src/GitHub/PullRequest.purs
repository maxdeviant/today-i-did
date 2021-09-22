module GitHub.PullRequest
  ( PullRequest(..)
  , findPullRequest
  , listComments
  ) where

import Prelude

import Control.Promise (Promise)
import Control.Promise as Promise
import Data.Function.Uncurried (Fn4, runFn4)
import Data.Newtype (class Newtype)
import Effect.Aff (Aff)
import GitHub.Client (GitHubClient)

newtype PullRequest = PullRequest
  { number :: Int
  , title :: String
  }

derive instance newtypePullRequest :: Newtype PullRequest _

derive newtype instance showPullRequest :: Show PullRequest

foreign import findPullRequestImpl :: Fn4 GitHubClient String String Int (Promise PullRequest)

findPullRequest :: GitHubClient -> String -> String -> Int -> Aff PullRequest
findPullRequest client owner repo prNumber = Promise.toAff $ runFn4 findPullRequestImpl client owner repo prNumber

type Comment =
  { body :: String
  , user :: { login :: String }
  }

foreign import listCommentsImpl :: Fn4 GitHubClient String String Int (Promise (Array Comment))

listComments :: GitHubClient -> String -> String -> Int -> Aff (Array Comment)
listComments client owner repo prNumber = Promise.toAff $ runFn4 listCommentsImpl client owner repo prNumber
