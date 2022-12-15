app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports []
    provides [main] to pf

main = \data ->
    when Str.fromUtf8 data is
        Ok str ->
            if Str.toUtf8 str != data then
                crash "Data is not the same after converting to and from Str"
            else
                0
        Err _ -> 1
