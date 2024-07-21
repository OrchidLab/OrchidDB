const std = @import("std");
const db = @import("orchard.zig");

pub fn repl() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = allocator.allocator();
    var orchard = try db.OrchardDB.init(gpa, .{});
    defer orchard.deinit();

    var writer = std.io.getStdOut().writer();
    var reader = std.io.getStdIn().reader();
    _ = try writer.print("[INFO] OrchardDB In-Memory Instance\n[INFO] Type `help` for a list of operatons\n# ", .{});
    outer: while (true) {
        var buffer: [1024]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (std.mem.containsAtLeast(u8, line, 1, "GET")) {
                if (line.len <= 3) break;
                const get = orchard.get(line[4..]) orelse {
                    try writer.print("[INFO] Key ({s}) does not exist in DB\n# ", .{line[4..]});
                    break;
                };
                try writer.print("# {s}\n# ", .{get});
                break;
            } else if (std.mem.containsAtLeast(u8, line, 1, "PUT")) {
                if (line.len <= 3) break;
                var kv = std.mem.splitScalar(u8, line[4..], ' ');
                const key = kv.next() orelse {
                    _ = try writer.print("[INFO] Key not inputted\n# ", .{});
                    break;
                };
                const value = kv.next() orelse {
                    try writer.print("[INFO] Value not inputted\n# ", .{});
                    break;
                };
                _ = try orchard.put(key, value);
                try writer.print("# OK\n# ", .{});
            } else if (std.mem.containsAtLeast(u8, line, 1, "DELETE")) {
                if (line.len <= 6) break;
                if (orchard.delete(line[7..])) {
                    try writer.print("# OK\n# ", .{});
                } else |_| {
                    try writer.print("[INFO] Key ({s}) does not exist in DB\n# ", .{line[7..]});
                    break;
                }
            } else if (std.mem.eql(u8, line, "help")) {
                try writer.print("[INFO] Operations:\n GET key\n PUT key value\n DELETE key\n exit\thelp\n# ", .{});
            } else if (std.mem.eql(u8, line, "exit")) {
                break :outer;
            } else {
                try writer.print("[INFO] Invalid Command\n# ", .{});
            }
        }
    }
}
