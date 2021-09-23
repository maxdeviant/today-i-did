{ name = "today-i-did"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "arrays"
  , "console"
  , "dotenv"
  , "effect"
  , "either"
  , "foldable-traversable"
  , "functions"
  , "integers"
  , "interpolate"
  , "maybe"
  , "newtype"
  , "node-buffer"
  , "node-fs-aff"
  , "node-process"
  , "prelude"
  , "psci-support"
  , "strings"
  , "stringutils"
  , "transformers"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
