# Roc-fuzz

The goal of this repo is to enable fuzzing of roc applications.
The main target is fuzzing parts of the standard library.
It should hopefully be able to catch some bugs especially memory safety ones in the zig builtins.

## Dependencies

This requires [afl.rs](https://github.com/rust-fuzz/afl.rs) which can be installed with: `cargo install afl`

If using any sanitizer other than the fuzzer, it also requires nightly rust to enable.

## How to use

Currently, this requires a special build of the compiler on the `enable-fuzzing` branch.
Shortly, this should get merged into main, but still requires a compiling from source and feature flag to enable.
Start by picking by building roc:
```sh
cargo build --features sanitizers --bin roc
```

Note: From this point forward, `roc` means the binary generate from the above command in `target/debug/roc`


Next, we can use roc to build a fuzz target. They all live in the `fuzz_targets` directory.
For building fuzz targets, we need to enable sanitizers. At a minimum, the `fuzzer` sanitizer is required.
On top of that `address`, `memory`, and `thread` sanitizers are available. I advise using `address` sanitizer in general.
We can build `listrange.roc` with:
```sh
ROC_SANITIZERS="address,fuzzer" roc build --no-link --optimize fuzz_targets/listrange.roc
````

This will generate an instrumented object file. For this platform we need a static library.
That can be create with:
```sh
ar rcs fuzz_targets/libroc-fuzz.a fuzz_targets/libroc-fuzz.o
```

Now that we have the genreated static library, we can compile the fuzzing platform with:
```sh
RUSTFLAGS="-Z sanitizer=address" cargo afl build --release
```

Finally, the fuzzing can be run with:
```sh
cargo afl fuzz -i in -o out target/release/roc-fuzz
```

## Other Notes

`afl` has a lot of powerful options, but even something this simple should work for many application.
More docs specific to `afl` can be found at [aflplus.plus](https://aflplus.plus/).
If you plan to do a longer term fuzz, I highly advise looking at the docs on [using multiple cores](https://aflplus.plus/docs/fuzzing_in_depth/#c-using-multiple-cores).

Often times I notice that `afl` only gets to about `15%` coverage.
I do not think this is a bug. I think that there is just a lot of code that never gets run.
This is capable of finding bugs and generally increasing coverage, so I am not too woried about it.

The `in/` directory contains the seeds for fuzzing. Currently it is a simple short seed.
The seeds can be tailored to specific functions in order to help fuzzing go faster.

If you switch from fuzzing one applications to another remember to clear the `out/` directory.

Crashes will be found in `out/default/crashes/`.
They will often be very complex. I advise minimizing them before looking them over.
To minimize a crash, simply run:
```sh
cargo afl tmin -i out/default/crashes/{file name} -o {minimized crash file} target/release/roc-fuzz
```

You can run a crash though the app by simply piping it through stdin: `./target/release/roc-fuzz < {file}`

In the future, I hope to add a way to pretty print the crashes. That should help a human understand them better.
