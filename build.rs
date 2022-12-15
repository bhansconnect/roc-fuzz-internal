fn main() {
    #[cfg(not(windows))]
    println!("cargo:rustc-link-lib=static=roc-fuzz");

    #[cfg(windows)]
    println!("cargo:rustc-link-lib=static=libroc-fuzz");

    println!("cargo:rustc-link-search=./fuzz_targets");
}
