module Linear.Client
  ( LinearClient
  , ApiKey(..)
  , mkClient
  ) where

import Effect (Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)

newtype ApiKey = ApiKey String

foreign import data LinearClient :: Type

foreign import mkClientImpl :: EffectFn1 ApiKey LinearClient

mkClient :: ApiKey -> Effect LinearClient
mkClient apiKey = runEffectFn1 mkClientImpl apiKey
