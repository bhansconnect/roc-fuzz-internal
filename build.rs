fn main() {
    #[cfg(not(windows))]
    println!("cargo:rustc-link-lib=static=roc-fuzz");

    #[cfg(windows)]
    println!("cargo:rustc-link-lib=static=libroc-fuzz");

    println!("cargo:rustc-link-search=./roc_targets");

    for file in glob::glob("./roc_targets/*roc-fuzz*").expect("Failed to read glob pattern") {
        println!(
            "cargo:rerun-if-changed={}",
            file.expect("Failed to load globbed file").display()
        );
    }
}
