app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryStr, ratio, u64InInclusiveRange}]
    provides [main] to pf

main = \data ->
    ar1 = new data

    {state: ar2, value: str1} = arbitraryStr ar1

    {state: ar3, value: reference1} = ratio ar2 1 2
    {value: count} = u64InInclusiveRange ar3 0 512

    tmp1 =
        if reference1 then
            str1
        else
            ""

    out = Str.repeat str1 (Num.toNat count)
    if count == 0 && out != "" then
        crash "when repeating zero times, we should always get the empty string"
    else
        # This is needed to keep the references to tmp alive
        Str.countUtf8Bytes tmp1
        |> Num.toU8
