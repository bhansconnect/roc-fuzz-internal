app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryListU8}]
    provides [main] to pf

main = \data ->
    new data
    |> arbitraryListU8
    |> .value
    |> List.len
    |> Num.toU8
