app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports []
    provides [main] to pf

main = \data ->
    startSel = getOrZero data 0
    startNumU8 = getOrZero data 1 
    start =
        if startSel % 2 == 0 then
            At startNumU8
        else
            After startNumU8

    endSel = getOrZero data 2
    endNumU8 = getOrZero data 3 
    end =
        if endSel % 3 == 0 then
            At endNumU8
        else if endSel % 3 == 1 then
            Before endNumU8
        else
            Length (Num.toNat endNumU8)

    stepNumU8 = getOrZero data 4 

    range = List.range {start, end, step: stepNumU8}
    if List.isEmpty range then
        0
    else
        1

getOrZero = \data, i ->
    when List.get data i is
        Ok x -> x
        Err _ -> 0
