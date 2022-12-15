app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports []
    provides [main] to pf

main = \data ->
    startSel = getOrZero data 0
    startNumU8 = getOrZero data 1 
    startNumI8 =
        startNumU8
        |> Num.bitwiseAnd 0x7F
        |> Num.toI8
        |> \n ->
            if startNumU8 > 0x7F then
                -1 * n
            else
                n
    start =
        if startSel % 2 == 0 then
            At startNumI8
        else
            After startNumI8
    endSel = getOrZero data 2
    endNumU8 = getOrZero data 3 
    endNumI8 =
        endNumU8
        |> Num.bitwiseAnd 0x7F
        |> Num.toI8
        |> \n ->
            if endNumU8 > 0x7F then
                -1 * n
            else
                n
    end =
        if endSel % 3 == 0 then
            At endNumI8
        else if endSel % 3 == 1 then
            Before endNumI8
        else
            Length (Num.toNat endNumU8)
    stepNumU8 = getOrZero data 4 
    stepNumI8 =
        stepNumU8
        |> Num.bitwiseAnd 0x7F
        |> Num.toI8
        |> \n ->
            if endNumU8 > 0x7F then
                -1 * n
            else
                n
    range = List.range {start, end, step: stepNumI8}
    if List.isEmpty range then
        0
    else
        1

getOrZero = \data, i ->
    when List.get data i is
        Ok x -> x
        Err _ -> 0
