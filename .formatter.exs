# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  imported_deps: [:typed_struct],
  locals_without_parens: [
    # typed_struct
    field: 2,
    field: 3
  ]
]
