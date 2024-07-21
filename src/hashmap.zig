//! File: hashmap.zig
//! Author: Aryan Suri: <arysuri at proton dot me>
//! Description: Orchard, is a distributed key-value store in Zig
//! Licence: MIT
//! Note: This HashMap is a derivative of my HashMap source file : https://raw.githubusercontent.com/aryanrsuri/map/master/src/map.zig

const std = @import("std");
pub const HashMap = struct {
    array: []?Entry,
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex,
    load_factor: usize,
    pub const Entry = struct { key: []const u8, value: []const u8, version: i64 };
    pub fn init(allocator: std.mem.Allocator, capacity: usize, load_factor: usize) !@This() {
        const array: []?Entry = try allocator.alloc(?Entry, capacity);
        @memset(array, null);
        return .{ .array = array, .allocator = allocator, .load_factor = load_factor, .mutex = std.Thread.Mutex{} };
    }

    pub fn deinit(self: *@This()) void {
        for (self.array) |item| {
            if (item) |row| {
                self.allocator.free(row.key);
                self.allocator.free(row.value);
            }
        }
        self.allocator.free(self.array);
        self.* = undefined;
    }

    pub fn get(self: *@This(), key: []const u8) ?[]const u8 {
        self.mutex.lock();
        defer self.mutex.unlock();
        var index = hash(key) % self.array.len;

        while (self.array[index] != null) : (index += 1) {
            if (std.mem.eql(u8, self.array[index].?.key, key)) return self.array[index].?.value;
            if (index == self.array.len - 1) break;
        }
        return null;
    }

    pub fn set(self: *@This(), key: []const u8, value: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.size() >= self.array.len * 3 / 4) try self.grow(self.array.len * 2);
        var index = hash(key) % self.array.len;
        const v = try self.allocator.dupe(u8, value);
        while (self.array[index]) |item| : (index = (index + 1) % self.array.len) {
            if (std.mem.eql(u8, item.key, key)) {
                self.allocator.free(self.array[index].?.value);
                self.array[index].?.value = v;
                return;
            }
        }

        const k = try self.allocator.dupe(u8, key);
        self.array[index] = .{ .key = k, .value = v, .version = std.time.timestamp() };
    }

    pub fn delete(self: *@This(), key: []const u8) !void {
        var index = hash(key) % self.array.len;
        while (self.array[index]) |item| : (index = (index + 1) % self.array.len) {
            if (std.mem.eql(u8, key, item.key)) {
                self.allocator.free(item.key);
                self.allocator.free(item.value);
                self.array[index] = null;
                return;
            }
        }

        return error.KeyNotFound;
    }

    pub fn debug(self: *@This(), title: ?[]const u8, omit: bool) void {
        if (title) |string| {
            std.debug.print("\n{s}\n", .{string});
        }
        std.debug.print("Index\tTimestamp\tKey\tValue\n", .{});
        for (self.array, 0..) |option, index| {
            if (option) |item| {
                std.debug.print("{}\t{}\t{s}\t{s}\n", .{ index, item.version, item.key, item.value });
            } else {
                if (!omit) {
                    std.debug.print("{}\t0\t\t0\t0\n", .{index});
                }
            }
        }
    }

    fn grow(self: *@This(), capacity: usize) !void {
        const grown = try self.allocator.realloc(self.array, capacity);
        for (grown[self.array.len..]) |*item| {
            item.* = null;
        }
        self.array = grown;
    }

    fn size(self: *@This()) usize {
        var count: usize = 0;
        for (self.array) |item| {
            if (item != null) count += 1;
        }
        return count;
    }

    fn hash(key: []const u8) usize {
        var h: usize = 0xcbf29ce484222325;
        for (key) |char| {
            h = (h ^ char) *% 0x100000001b3;
        }
        return h;
    }
};

test "Hash Map" {
    const allocator = std.testing.allocator;
    var hm = try HashMap.init(allocator, 6, (3 / 4));
    defer hm.deinit();
    {
        try hm.set("key1", "4");
        try hm.set("key2", "4");
        try hm.set("key3", "4");
        try hm.set("key4", "4");
        try hm.set("key5", "4");
        try hm.set("key6", "4");
        try hm.set("key7", "4");
        try hm.set("key8", "4");
        std.time.sleep(1_000_000_000);
        try hm.set("key8", "10");
        try hm.set("key9", "4");
        try hm.set("key10", "4");
        try hm.set("key11", "4");
        try std.testing.expectEqualStrings("10", hm.get("key8").?);
        try std.testing.expectEqual(null, hm.get("key12"));
        _ = try hm.delete("key8");
        hm.debug("HashMap", false);
    }
}
