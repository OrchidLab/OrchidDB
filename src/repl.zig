const std = @import("std");
const db = @import("orchard.zig");

const Command = enum {
    GET,
    SET,
    DELETE,
    HELP,
    EXIT,
    UNKNOWN,

    pub fn parse(line: []const u8) @This() {
        if (std.mem.startsWith(u8, line, "GET")) return .GET;
        if (std.mem.startsWith(u8, line, "SET")) return .SET;
        if (std.mem.startsWith(u8, line, "DELETE")) return .DELETE;
        if (std.mem.startsWith(u8, line, "help")) return .HELP;
        if (std.mem.startsWith(u8, line, "exit")) return .EXIT;
        return .UNKNOWN;
    }
};

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
            const command = Command.parse(line);
            switch (command) {
                .GET => {
                    if (line.len < 4) break;
                    const get = orchard.get(line[4..]) orelse {
                        try writer.print("[INFO] Key ({s}) does not exist in DB\n# ", .{line[4..]});
                        break;
                    };
                    try writer.print("# {s}\n# ", .{get});
                },
                .SET => {
                    if (line.len < 4) break;
                    var kv = std.mem.splitScalar(u8, line[4..], ' ');
                    const key = kv.next() orelse {
                        _ = try writer.print("[INFO] Key not inputted\n# ", .{});
                        break;
                    };
                    const value = kv.next() orelse {
                        try writer.print("[INFO] Value not inputted\n# ", .{});
                        break;
                    };
                    _ = try orchard.set(key, value);
                    try writer.print("# OK\n# ", .{});
                },
                .DELETE => {
                    if (line.len < 7) break;
                    if (orchard.delete(line[7..])) {
                        try writer.print("# OK\n# ", .{});
                    } else |_| {
                        try writer.print("[INFO] Key ({s}) does not exist in DB\n# ", .{line[7..]});
                        break;
                    }
                },
                .HELP => try writer.print("[INFO] Operations:\n# GET key\n# SET key value\n# DELETE key\n# exit\n# help\n# ", .{}),
                .EXIT => break :outer,
                else => try writer.print("[INFO] Invalid Command\n# ", .{}),
            }
        }
    }
}
