app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryStr, ratio}]
    provides [main] to pf

main = \data ->
    ar1 = new data

    {state: ar2, value: str1} = arbitraryStr ar1
    {state: ar3, value: reference1} = ratio ar2 1 2

    {state: ar4, value: str2} = arbitraryStr ar3
    {value: reference2} = ratio ar4 1 2

    tmp1 =
        if reference1 then
            str1
        else
            ""

    tmp2 =
        if reference2 then
            str2
        else
            ""

    out = Str.endsWith str1 str2
    if out then
        Str.countUtf8Bytes tmp2
        |> Num.add (Str.countUtf8Bytes tmp1)
        |> Num.toU8
    else
        # This is needed to keep the references to tmp alive
        Str.countUtf8Bytes tmp1
        |> Num.add (Str.countUtf8Bytes tmp2)
        |> Num.toU8
