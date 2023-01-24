app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryStr, ratio}]
    provides [main] to pf

main = \data ->
    ar1 = new data

    {state: ar2, value: str1} = arbitraryStr ar1
    {state: ar3, value: str2} = arbitraryStr ar2

    {state: ar4, value: reference1} = ratio ar3 1 2
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

    splits = Str.split str1 str2
    rejoined = Str.joinWith splits str2
    if rejoined != str1 then
        crash "the rejoined string does not equal the original string"
    else
        # This is needed to keep the references to tmp alive
        x = Str.countUtf8Bytes tmp1
        y = Str.countUtf8Bytes tmp2
        Num.addWrap x y
        |> Num.toU8
