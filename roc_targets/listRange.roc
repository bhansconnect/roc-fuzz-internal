app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports []
    provides [main] to pf

main = \data ->
    when data is
        [startSel, startNumU8, endSel, endNumU8, stepNumU8, ..] ->
            startAfter = startSel % 2 == 0
            start =
                if startAfter then
                    After startNumU8
                else
                    At startNumU8

            end =
                if endSel % 3 == 0 then
                    At endNumU8
                else if endSel % 3 == 1 then
                    Before endNumU8
                else
                    # Length will panic if it wraps passed the end of a numeric range.
                    # Limit the length to avoid that
                    endNumNat = Num.toNat endNumU8
                    correctedStep =
                        if stepNumU8 == 0 then
                            1
                        else
                            Num.toNat stepNumU8
                    maxLen =
                        256
                        |> Num.subSaturated (Num.toNat startNumU8)
                        |> Num.subSaturated (if startAfter then correctedStep else 0)
                        |> Num.divTrunc correctedStep

                    len =
                        if endNumNat > maxLen then
                            maxLen
                        else
                            endNumNat
                    Length len

            range = List.range {start, end, step: stepNumU8}
            if List.isEmpty range then
                0
            else
                1
        _ ->
            2
