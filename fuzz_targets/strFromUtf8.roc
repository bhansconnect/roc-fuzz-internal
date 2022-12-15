app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports []
    provides [main] to pf

main = \data ->
    when Str.fromUtf8 data is
        Ok _ -> 0
        Err _ -> 1
