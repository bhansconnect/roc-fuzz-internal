platform "roc-fuzz"
    requires {} { main : List U8 -> U8 }
    exposes []
    packages {}
    imports []
    provides [mainForHost]

mainForHost : List U8 -> U8
mainForHost = \x -> main x
