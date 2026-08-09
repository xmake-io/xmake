const std = @import("std");

extern fn add(a: i32, b: i32) i32;

pub fn main() !void {
    std.debug.print("Hello, {s} - {d}!\n", .{"world", add(1, 1)});
}
