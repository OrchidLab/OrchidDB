//! File: orchard.zig
//! Author: Aryan Suri: <arysuri at proton dot me>
//! Description: Orchard, is a distributed key-value store in Zig
//! Licence: MIT

const std = @import("std");
const map = @import("hashmap.zig");
pub const OrchardDB = struct {
    hashmap: *map.HashMap,
    allocator: std.mem.Allocator,

    // TODO: Persistance fields should be abstracted to a config to allow for in-memory OR persistant store.
    operations: usize = 0,
    persistant_to: usize,
    log: std.fs.File,
    disk: std.fs.File,

    pub fn init(allocator: std.mem.Allocator, disk_path: []const u8, log_path: []const u8, persistant_to: usize) !@This() {
        const disk = try std.fs.cwd().createFile(disk_path, .{ .read = true, .truncate = false });
        const log = try std.fs.cwd().createFile(log_path, .{ .read = true, .truncate = false });
        const hashmap = try allocator.create(map.HashMap);
        errdefer allocator.destroy(hashmap);
        hashmap.* = try map.HashMap.init(allocator, 1024, (3 / 4));
        return .{ .hashmap = hashmap, .allocator = allocator, .disk = disk, .log = log, .persistant_to = persistant_to };
    }

    pub fn deinit(self: *@This()) void {
        self.hashmap.deinit();
        self.allocator.destroy(self.hashmap);
        self.* = undefined;
    }

    pub fn put(self: *@This(), key: []const u8, value: []const u8) !void {
        try self.write_to_log("PUT", key, value);
        try self.hashmap.set(key, value);
        self.operations += 1;
        if (self.operations > self.persistant_to) try self.sync();
    }

    pub fn get(self: *@This(), key: []const u8) ?[]const u8 {
        return self.hashmap.get(key);
    }

    pub fn delete(self: *@This(), key: []const u8) !void {
        try self.write_to_log("DELETE", key, "");
        try self.hashmap.delete(key);
    }

    fn sync(self: *@This()) !void {
        try self.write_to_disk();
        try self.log.setEndPos(0);
        try self.log.sync();
        self.operations = 0;
    }

    fn recover(self: *@This()) !void {
        var disk_buffer: [4096]u8 = undefined;
        while (try self.disk.reader().readUntilDelimiterOrEof(&disk_buffer, '\n')) |line| {
            var token = std.mem.tokenizeAny(u8, line, " ");
            const key = token.next() orelse continue;
            const value = token.next() orelse continue;
            try self.hashmap.set(key, value);
        }

        var log_buffer: [4096]u8 = undefined;
        try self.log.seekTo(0);
        if (try self.log.getEndPos() == 0) return;

        while (try self.log.reader().readUntilDelimiterOrEof(&log_buffer, '\n')) |line| {
            std.debug.print("line {s}", .{line});
            var token = std.mem.tokenizeAny(u8, line, " ");
            const operation = token.next() orelse continue;
            const key = token.next() orelse continue;
            const value = token.next() orelse continue;

            if (std.mem.eql(u8, operation, "PUT")) {
                try self.hashmap.set(key, value);
            } else if (std.mem.eql(u8, operation, "DELETE")) {
                self.hashmap.delete(key) catch {};
            }
        }
    }

    fn write_to_disk(self: *@This()) !void {
        try self.disk.seekTo(0);
        for (self.hashmap.array) |record| {
            if (record) |row| {
                const enter = try std.fmt.allocPrint(self.allocator, "{s} {s} {d}\n", .{ row.key, row.value, row.version });
                defer self.allocator.free(enter);
                try self.disk.writeAll(enter);
            }
        }
        try self.disk.sync();
    }

    fn write_to_log(self: *@This(), operation: []const u8, key: []const u8, value: []const u8) !void {
        try self.log.seekFromEnd(0);
        const enter = try std.fmt.allocPrint(self.allocator, "{s} {s} {s}\n", .{ operation, key, value });
        defer self.allocator.free(enter);
        try self.log.writeAll(enter);
        try self.log.sync();
    }
};

test "Key Value Store" {
    const alloc = std.testing.allocator;
    var orchard = try OrchardDB.init(alloc, "../.tmp/.orchard.test.db", "../.tmp/.orchard.test.log", 500);
    defer orchard.deinit();
    orchard.hashmap.debug("nothing", true);
    try orchard.recover();
    orchard.hashmap.debug("should have 6 keys", true);
    // _ = try orchard.put("key", "1");
    // orchard.hashmap.debug("key1", true);
    // _ = try orchard.put("key1", "2");
    // _ = try orchard.put("key2", "3");
    // _ = try orchard.put("key3", "4");
    // try std.testing.expectEqualStrings("1", orchard.get("key").?);
    // _ = try orchard.delete("key");
    // try std.testing.expectEqual(null, orchard.get("key"));
}
