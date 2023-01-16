app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryStr, ratio}]
    provides [main] to pf

main = \data ->
    ar1 = new data

    {state: ar2, value: str1} = arbitraryStr ar1
    {value: reference1} = ratio ar2 1 2

    tmp1 =
        if reference1 then
            str1
        else
            ""

    out = Str.toU128 str1
    when out is
        Ok _ ->
            # This is needed to keep the references to tmp alive
            Str.countUtf8Bytes tmp1
            |> Num.toU8
        Err _ ->
            # This is needed to keep the references to tmp alive
            Str.countUtf8Bytes tmp1
            |> Num.addWrap 1
            |> Num.toU8
