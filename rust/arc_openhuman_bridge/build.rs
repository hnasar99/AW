fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("android") {
        // max-page-size is set by the Android build script. Set the common
        // page size on this final shared-library link as well: PT_LOAD
        // alignment alone does not align the end of PT_GNU_RELRO.
        println!("cargo:rustc-link-arg=-Wl,-z,common-page-size=16384");
    }
}
