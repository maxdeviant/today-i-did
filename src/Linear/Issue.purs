module Linear.Issue
  ( Issue(..)
  , IssueId(..)
  , findIssue
  ) where

import Prelude

import Control.Promise (Promise)
import Control.Promise as Promise
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Newtype (class Newtype)
import Effect.Aff (Aff)
import Linear.Client (LinearClient)

newtype IssueId = IssueId String

derive instance newtypeIssueId :: Newtype IssueId _

derive newtype instance showIssueId :: Show IssueId

newtype Issue = Issue { identifier :: IssueId }

derive instance newtypeIssue :: Newtype Issue _

derive newtype instance showIssue :: Show Issue

foreign import findIssueImpl :: Fn2 LinearClient IssueId (Promise Issue)

findIssue :: LinearClient -> IssueId -> Aff Issue
findIssue client id = Promise.toAff $ runFn2 findIssueImpl client id
