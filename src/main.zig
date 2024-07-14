const std = @import("std");
const OrchardDB = @import("orchard.zig").OrchardDB;

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = allocator.allocator();
    var orchard = try OrchardDB.init(gpa, "./.tmp/.orchard.prd1.db", "./.tmp/.orchard.prd1.log", 512);
    defer orchard.deinit();
    std.debug.print("[INFO] Begin insert of 4095 items, evey 100th item a key will be clobbered. \n", .{});
    var keyb: [16]u8 = undefined;
    var valb: [16]u8 = undefined;
    for (1..4096) |i| {
        if (i % 100 == 0) {
            const key = try std.fmt.bufPrint(&keyb, "KEY{d}", .{i - 1});
            try orchard.delete(key);
        } else {
            const key = try std.fmt.bufPrint(&keyb, "KEY{d}", .{i});
            const value = try std.fmt.bufPrint(&valb, "VAL{d}", .{i});
            try orchard.put(key, value);
        }
    }
    std.debug.print("[INFO] Insert ended. \n", .{});
}
