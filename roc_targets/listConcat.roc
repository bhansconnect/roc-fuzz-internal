app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryListU8, ratio}]
    provides [main] to pf

main = \data ->
    ar1 = new data

    {state: ar2, value: bytes1}= arbitraryListU8 ar1
    len1 = List.len bytes1

    {state: ar3, value: bytes2}= arbitraryListU8 ar2
    len2 = List.len bytes2

    {state: ar4, value: reference1} = ratio ar3 1 2
    {value: reference2} = ratio ar4 1 2

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
    if List.len out != len1 + len2 then
        crash "output list does not have the size of the two base list joined"
    else
        # This is needed to keep the references to tmp alive
        x = List.first tmp1 |> Result.withDefault 0
        y = List.first tmp2 |> Result.withDefault 0
        Num.addWrap x y
