const std = @import("std");
const db = @import("orchard.zig");
const repl = @import("repl.zig");
const tcp = @import("tcp.zig");
pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = allocator.allocator();
    var orchard = try db.OrchardDB.init(gpa, .{});
    defer orchard.deinit();
    _ = try repl.repl(&orchard);
    // _ = try tcp.http();
}
