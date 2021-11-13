extern crate base64;

use base64::{encode, decode};

fn main() {
    let a = b"hello world";
    let b = "aGVsbG8gd29ybGQ=";

    assert_eq!(encode(a), b);
    assert_eq!(a, &decode(b).unwrap()[..]);
}
