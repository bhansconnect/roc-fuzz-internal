app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryByteSize, bytes, ratio}]
    provides [main] to pf

main = \data ->
    ar1 = new data

    {state: ar2, value: len1}= arbitraryByteSize ar1
    {state: ar3, value: bytes1} =
        when bytes ar2 len1 is
            Ok x -> x
            Err _ -> crash "This should be impossible since we grabbed the size directly"

    {state: ar4, value: len2}= arbitraryByteSize ar3
    {state: ar5, value: bytes2} =
        when bytes ar4 len2 is
            Ok x -> x
            Err _ -> crash "This should be impossible since we grabbed the size directly"

    {state: ar6, value: reference1} = ratio ar5 1 2
    {value: reference2} = ratio ar6 1 2

    tmp1 =
        if reference1 then
            bytes1
        else
            []

    tmp2 =
        if reference2 then
            bytes2
        else
            []

    out = List.concat bytes1 bytes2
    if List.len out != len1 +len2 then
        crash "output list does not have the size of the two base list joined"
    else
        # This is needed to keep the references to tmp alive
        x = List.first tmp1 |> Result.withDefault 0
        y = List.first tmp2 |> Result.withDefault 0
        Num.addWrap x y
