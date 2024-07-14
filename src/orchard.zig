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
        const log = try std.fs.cwd().createFile(log_path, .{ .read = true });
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
        if (self.operations > self.persistant_to) try self.write_to_disk();
    }

    pub fn get(self: *@This(), key: []const u8) ?[]const u8 {
        return self.hashmap.get(key);
    }

    pub fn delete(self: *@This(), key: []const u8) !void {
        try self.write_to_log("DELETE", key);
        try self.hashmap.delete(key);
    }

    pub fn write_to_disk(self: *@This()) !void {
        try self.disk.seekTo(0);
        for (self.hashmap.array) |record| {
            if (record) |row| {
                const enter = try std.fmt.allocPrint(self.allocator, "{s} {s} {d}\n", .{ row.key, row.value, row.version });
                defer self.allocator.free(enter);
                try self.disk.writeAll(enter);
            }
        }
        try self.disk.sync();
        self.operations = 0;
    }

    pub fn write_to_log(self: *@This(), operation: []const u8, key: []const u8, value: []const u8) !void {
        try self.log.seekFromEnd(0);
        const enter = try std.fmt.allocPrint(self.allocator, "{s} {s} {s}\n", .{ operation, key, value });
        defer self.allocator.free(enter);
        try self.log.writeAll(enter);
        try self.log.sync();
    }
};

test "Key Value Store" {
    const alloc = std.testing.allocator;
    var orchard = try OrchardDB.init(alloc, "./.orchard.1.db", "./.orchard.1.log", 64);
    defer orchard.deinit();
    _ = try orchard.put("key", "1");
    try std.testing.expectEqualStrings("1", orchard.get("key").?);
    _ = try orchard.delete("key");
    try std.testing.expectEqual(null, orchard.get("key"));
}
