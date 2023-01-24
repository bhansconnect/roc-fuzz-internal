app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryStr, u64InInclusiveRange, ratio}]
    provides [main] to pf

main = \data ->
    ar1 = new data

    {state: ar2, value: str1} = arbitraryStr ar1

    {state: ar3, value: reference1} = ratio ar2 1 2

    {value: scalarValue} = u64InInclusiveRange ar3 0 (Num.toU64 Num.maxU32)

    tmp1 =
        if reference1 then
            str1
        else
            ""

    out = Str.startsWithScalar str1 (Num.toU32 scalarValue)

    # This is needed to keep the references to tmp alive
    Str.countUtf8Bytes tmp1
    |> Num.toU8
    |> Num.addWrap (if out then 1 else 0)