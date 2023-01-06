Bugs found in Roc via fuzzing:

 - Memory leak in Str.concat [roc#4846](https://github.com/roc-lang/roc/issues/4856)
 - Bug in borrow analysis leading to use-after-free or memory leak when host calls into Roc
