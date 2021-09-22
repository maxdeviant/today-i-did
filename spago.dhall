{ name = "today-i-did"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "console"
  , "dotenv"
  , "effect"
  , "either"
  , "functions"
  , "maybe"
  , "newtype"
  , "node-process"
  , "prelude"
  , "psci-support"
  , "transformers"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
