app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryListU8}, TotallyNotJson]
    provides [main] to pf

main = \data ->
    input =
        new data
        |> arbitraryListU8
        |> .value

    # To make other TotallyNotJson tests, only the decode type should need to change.
    result: Result Dec _
    result = Decode.fromBytes input TotallyNotJson.json

    when result is
        Ok decoded ->
            # We decoded successfully.
            # This value should always be able to re-encode.
            encoded =
                decoded
                |> Encode.toBytes TotallyNotJson.json

            # We should be able to decode one more time an ensure the value is the same
            redecoded =
                encoded
                |> Decode.fromBytes TotallyNotJson.json
                |> okOrCrash "could not re-decode TotallyNotJson payload"

            if decoded != redecoded then
                crash "original decoded value and re-decoded value do not match"
            else
                0
        Err _ ->
            # Nothing interesting to do in the case we can't decode
            1

okOrCrash = \res, msg ->
    when res is
        Ok x -> x
        Err _ -> crash msg
