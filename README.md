# Roc-fuzz

The goal of this repo is to enable fuzzing of roc applications.
The main target is fuzzing parts of the standard library.
It should hopefully be able to catch some bugs especially memory safety ones in the zig builtins.

Note: On the sanitizers really only fully catch bugs on linux. If you are on mac, fuzzing is likely to be less productive.

## Dependencies

This requires [cargo-fuzz](https://github.com/rust-fuzz/cargo-fuzz) which can be installed with: `cargo install cargo-fuzz`

If using any sanitizer other than the fuzzer, it also requires nightly rust to enable.

## How to use

This requires a special build of the compiler with the `sanitizers` feature flag.
Start by [building roc from source](https://github.com/roc-lang/roc/blob/main/BUILDING_FROM_SOURCE.md):
```sh
cargo build --features sanitizers --bin roc
```

Note: From this point forward, `roc` means the binary generate from the above command in `target/debug/roc`

Note: If you have `roc` in your path, you should be able to just use the `run.sh` or `run-many.sh` scripts to do everything below automatically.
That said, the script does require installing [gum](https://github.com/charmbracelet/gum).


Next, we can use roc to build a fuzz target. They all live in the `roc_targets` directory.
For building fuzz targets, we need to enable sanitizers. At a minimum, the `cargo-fuzz` sanitizer is required.
On top of that `address`, `memory`, and `thread` sanitizers are available. I advise using `address` sanitizer in general.
We can build `strFromUtf8.roc` with:
```sh
ROC_SANITIZERS="address,cargo-fuzz" roc build --no-link roc_targets/strFromUtf8.roc
````

This will generate an instrumented object file. For this platform we need a static library.
That can be create with:
```sh
ar rcs roc_targets/libroc-fuzz.a roc_targets/libroc-fuzz.o
```

Now that we have the generated static library, we can compile and run the fuzz target:
```sh
cargo fuzz run roc-fuzz
```

## Other Notes

If you switch from fuzzing one applications to another, remember to clear the `fuzz/corpus` and `fuzz/artifacts` directories.


For more options run `cargo fuzz run --help`.


Fuzzing can be done with optimized builds. Just add `--optimize` to the `roc build` invocation and `-O` to the `cargo fuzz run` invocation.


In the future, I hope to add a way to pretty print the crashes. That should help a human understand them better.
