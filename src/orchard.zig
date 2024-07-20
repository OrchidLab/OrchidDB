//! File: orchard.zig
//! Author: Aryan Suri: <arysuri at proton dot me>
//! Description: Orchard, is a distributed key-value store in Zig
//! Licence: MIT
const std = @import("std");
const map = @import("hashmap.zig");

// TODO: Is this better as a Generic, or in this switch format here?
pub const On = enum { disk, memory };
pub const Backend = union(enum) { disk: Disk, memory: Memory };
pub const Options = struct { backend: On = .memory, file_options: FileOptions = .{} };

/// Options for configuring a On Disk Files
/// Both the WAL Log and Disk File
/// max_operations: usize = Max operations computed before writing to Disk
/// log_path []const u8 = Path to WAL file
/// disk_path []const u8 = Path to DB File
pub const FileOptions = struct {
    max_operations: usize = 512,
    log_path: []const u8 = undefined,
    disk_path: []const u8 = undefined,
};

pub const OrchardDB = struct {
    backend: Backend,

    pub fn init(allocator: std.mem.Allocator, options: Options) !@This() {
        const backend = switch (options.backend) {
            .disk => Backend{ .disk = try Disk.init(allocator, options.file_options) },
            .memory => Backend{ .memory = try Memory.init(allocator) },
        };

        return .{ .backend = backend };
    }

    pub fn deinit(self: *OrchardDB) void {
        switch (self.backend) {
            inline else => |*on| return on.deinit(),
        }
        self.* = undefined;
    }

    pub fn put(self: *@This(), key: []const u8, value: []const u8) !void {
        switch (self.backend) {
            inline else => |*on| try on.put(key, value),
        }
    }

    pub fn get(self: *@This(), key: []const u8) ?[]const u8 {
        switch (self.backend) {
            inline else => |*on| return on.get(key),
        }
    }

    pub fn delete(self: *@This(), key: []const u8) !void {
        switch (self.backend) {
            inline else => |*on| try on.delete(key),
        }
    }
};

pub const Memory = struct {
    hashmap: *map.HashMap,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        const hashmap = try allocator.create(map.HashMap);
        errdefer allocator.destroy(hashmap);
        hashmap.* = try map.HashMap.init(allocator, 1024, (3 / 4));
        return .{ .hashmap = hashmap, .allocator = allocator };
    }

    pub fn deinit(self: *@This()) void {
        self.hashmap.deinit();
        self.allocator.destroy(self.hashmap);
        self.* = undefined;
    }

    pub fn put(self: *@This(), key: []const u8, value: []const u8) !void {
        if (key.len > 1024) return error.KeySizeExceeded;
        try self.hashmap.put(key, value);
    }

    pub fn get(self: *@This(), key: []const u8) ?[]const u8 {
        return self.hashmap.get(key);
    }

    pub fn delete(self: *@This(), key: []const u8) !void {
        try self.hashmap.delete(key);
    }
};

pub const Disk = struct {
    hashmap: *map.HashMap,
    allocator: std.mem.Allocator,

    // TODO: Persistance fields should be abstracted to a config to allow for in-memory OR persistant store.
    operations: usize = 0,
    max_operations: usize,
    log: std.fs.File,
    disk: std.fs.File,

    pub fn init(allocator: std.mem.Allocator, options: FileOptions) !@This() {
        const disk = try std.fs.cwd().createFile(options.disk_path, .{ .read = true, .truncate = false });
        const log = try std.fs.cwd().createFile(options.log_path, .{ .read = true, .truncate = false });
        const hashmap = try allocator.create(map.HashMap);
        errdefer allocator.destroy(hashmap);
        hashmap.* = try map.HashMap.init(allocator, 1024, (3 / 4));
        return .{ .hashmap = hashmap, .allocator = allocator, .disk = disk, .log = log, .max_operations = options.max_operations };
    }

    pub fn deinit(self: *@This()) void {
        self.hashmap.deinit();
        self.allocator.destroy(self.hashmap);
        self.* = undefined;
    }

    pub fn put(self: *@This(), key: []const u8, value: []const u8) !void {
        if (key.len > 1024) return error.KeySizeExceeded;
        try self.write_to_log("PUT", key, value);
        try self.hashmap.put(key, value);
        self.operations += 1;
        if (self.operations > self.max_operations) try self.sync();
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

test "In Memory" {
    const alloc = std.testing.allocator;
    var instance = try OrchardDB.init(alloc, .{});
    defer instance.deinit();
    try instance.put("key2", "value2");
    var e = instance.get("key2");
    std.debug.print("{any}\n", .{e});
    _ = try instance.delete("key2");
    e = instance.get("key2");
    std.debug.print("{any}\n", .{e});
}

test "File" {
    const alloc = std.testing.allocator;
    var instance = try OrchardDB.init(alloc, .{ .backend = .disk, .file_options = .{ .log_path = "../.tmp/.orchard.prd2.log", .disk_path = "../.tmp/.orchard.prd2.db" } });
    defer instance.deinit();
    try instance.put("key", "value");
    var e = instance.get("key");
    std.debug.print("{any}\n", .{e});
    _ = try instance.delete("key");
    e = instance.get("key");
    std.debug.print("{any}\n", .{e});
}
