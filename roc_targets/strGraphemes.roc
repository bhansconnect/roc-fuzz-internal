app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports [pf.Arbitrary.{new, arbitraryStr, ratio}]
    provides [main] to pf

main = \data ->
    ar1 = new data

    {state: ar2, value: str1} = arbitraryStr ar1
    count = Str.countGraphemes str1

    {value: reference1} = ratio ar2 1 2

    tmp1 =
        if reference1 then
            str1
        else
            ""

    graphemes = Str.graphemes str1
    if count != List.len graphemes then
        crash "the grapheme count and number of graphemes do no match"
    else
        # This is needed to keep the references to tmp alive
        Str.countUtf8Bytes tmp1
        |> Num.toU8
