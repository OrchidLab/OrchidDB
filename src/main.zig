const std = @import("std");
const OrchardDB = @import("orchard.zig").OrchardDB;

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = allocator.allocator();
    var orchard = try OrchardDB.init(gpa, "./.orchard.1.db", "./.orchard.1.log", 128);
    defer orchard.deinit();

    for (0..1000) |char| {
        const ch: u8 = @intCast(char);
        try orchard.put(&[_]u8{ch}, &[_]u8{ch});
    }
    std.debug.print("[INFO] Done\n", .{});
}
