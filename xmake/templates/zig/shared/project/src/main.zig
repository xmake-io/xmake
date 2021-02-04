const std = @import("std");

extern fn add(a: i32, b: i32) i32;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {s} - {d}!\n", .{"world", add(1, 1)});
}
