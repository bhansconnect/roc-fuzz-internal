fn main() {
    #[cfg(not(windows))]
    println!("cargo:rustc-link-lib=static=rocfuzz");

    #[cfg(windows)]
    println!("cargo:rustc-link-lib=static=librocfuzz");

    println!("cargo:rustc-link-search=.");
}
