#[cxx::bridge]
mod foo {
    extern "Rust" {
        fn add(a: i32, b: i32) -> i32;
    }
}
