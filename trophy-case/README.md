Bugs found in Roc via fuzzing:

 - Memory leak in Str.concat [roc#4846](https://github.com/roc-lang/roc/issues/4856)
 - Bug in borrow analysis leading to use-after-free or memory leak when host calls into Roc
 - Memory leak in List.concat [roc#4870](https://github.com/roc-lang/roc/issues/4870)
 - Second memory leak in List.concat [roc#4899](https://github.com/roc-lang/roc/issues/4899)
 - Memory leak in Str.trimLeft and Str.trimRight [roc#4900](https://github.com/roc-lang/roc/issues/4900)
