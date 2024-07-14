const std = @import("std");
const OrchardDB = @import("orchard.zig").OrchardDB;

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = allocator.allocator();
    var orchard = try OrchardDB.init(gpa, "./.orchard.1.db");
    defer orchard.deinit();

    var buffer: [5]u8 = undefined;
    for (48..128) |char| {
        const ch: u8 = @intCast(char);
        const key = try std.fmt.bufPrint(&buffer, "key_{c}", .{ch});
        try orchard.put(key, &[_]u8{ch});
    }
    std.debug.print("[INFO] Done\n", .{});
}
