app "libroc-fuzz"
    packages { pf: "../platform.roc" }
    imports []
    provides [main] to pf

main = \data ->
    set = List.walk data Set.empty Set.insert
    out =
        List.walk data 0 \x, elem ->
            if Set.contains set elem then
                x
            else
                crash "The set did not contain all inserted elements"
    set2 = List.walk data set Set.remove
    if Set.len set2 == 0 then
        out
    else
        crash "The set failed to remove all elements"
