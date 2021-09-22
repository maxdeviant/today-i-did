{ name = "today-i-did"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "arrays"
  , "console"
  , "dotenv"
  , "effect"
  , "either"
  , "functions"
  , "integers"
  , "maybe"
  , "newtype"
  , "node-process"
  , "prelude"
  , "psci-support"
  , "strings"
  , "transformers"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
