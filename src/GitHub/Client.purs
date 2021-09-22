module GitHub.Client
  ( GitHubClient
  , PersonalAccessToken(..)
  , mkClient
  ) where

import Effect (Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)

newtype PersonalAccessToken = PersonalAccessToken String

foreign import data GitHubClient :: Type

foreign import mkClientImpl :: EffectFn1 PersonalAccessToken GitHubClient

mkClient :: PersonalAccessToken -> Effect GitHubClient
mkClient token = runEffectFn1 mkClientImpl token
