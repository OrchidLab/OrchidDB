//! File: orchard.zig
//! Author: Aryan Suri: <arysuri at proton dot me>
//! Description: Orchard, is a distributed key-value store in Zig
//! Licence: MIT
const std = @import("std");
const map = @import("hashmap.zig");

pub const OrchardDB = struct {
    ops: usize = 0,
    disk: std.fs.File,
    hashmap: *map.HashMap,
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator, diskpath: []const u8) !@This() {
        const disk = try std.fs.cwd().createFile(diskpath, .{ .read = true, .truncate = false });
        const hashmap = try allocator.create(map.HashMap);
        errdefer allocator.destroy(hashmap);
        hashmap.* = try map.HashMap.init(allocator, 64);
        return .{ .hashmap = hashmap, .allocator = allocator, .disk = disk };
    }

    pub fn deinit(self: *@This()) void {
        self.hashmap.deinit();
        self.allocator.destroy(self.hashmap);
        self.* = undefined;
    }

    pub fn put(self: *@This(), key: []const u8, value: []const u8) !void {
        try self.hashmap.set(key, value);
        self.ops += 1;
        if (self.ops > 32) try self.write();
    }

    pub fn get(self: *@This(), key: []const u8) ?[]const u8 {
        return self.hashmap.get(key);
    }

    pub fn delete(self: *@This(), key: []const u8) !void {
        try self.hashmap.delete(key);
    }

    pub fn write(self: *@This()) !void {
        try self.disk.seekTo(0);
        for (self.hashmap.array) |record| {
            if (record) |row| {
                const enter = try std.fmt.allocPrint(self.allocator, "{s} {s} {d}\n", .{ row.key, row.value, row.version });
                defer self.allocator.free(enter);
                try self.disk.writeAll(enter);
            }
        }
        try self.disk.sync();
        self.ops = 0;
    }
};

test "Key Value Store" {
    const alloc = std.testing.allocator;
    var orchard = try OrchardDB.init(alloc, "./.orchard.1.db");
    defer orchard.deinit();
    _ = try orchard.put("key", "1");
    try std.testing.expectEqualStrings("1", orchard.get("key").?);
    _ = try orchard.delete("key");
    try std.testing.expectEqual(null, orchard.get("key"));
}
