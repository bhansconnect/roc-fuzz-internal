app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports []
    provides [main] to pf

main = \data ->
    when data is
        [startSel, startNumU8, endSel, endNumU8, stepNumU8, ..] ->
            start =
                if startSel % 2 == 0 then
                    At startNumU8
                else
                    After startNumU8

            end =
                if endSel % 3 == 0 then
                    At endNumU8
                else if endSel % 3 == 1 then
                    Before endNumU8
                else
                    Length (Num.toNat endNumU8)

            range = List.range {start, end, step: stepNumU8}
            if List.isEmpty range then
                0
            else
                1
        _ ->
            2
