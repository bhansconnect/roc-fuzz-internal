app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryListU8}]
    provides [main] to pf

main = \data ->
    bytes =
        new data
        |> arbitraryListU8
        |> .value
    str =
        when Str.fromUtf8 bytes is
            Ok s -> s
            Err (BadUtf8 _ index) ->
                # Even though this failed, we can stil parse the utf8 up to this index.
                when Str.fromUtf8Range bytes { start: 0, count: index } is
                    Ok s -> s
                    Err _ -> crash "This subset of the string should be valid for conversion to utf8"

    if Str.toUtf8 str != List.takeFirst bytes (Str.countUtf8Bytes str) then
        crash "Data is not the same after converting to and from Str"
    else
        0
