const std = @import("std");
const http = @import("http.zig");
const OrchardDB = @import("orchard.zig").OrchardDB;
const net = std.net;
const mem = std.mem;
pub fn serve() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = allocator.allocator();
    var orchard = try OrchardDB.init(gpa, "./.tmp/.orchard.prd1.db", "./.tmp/.orchard.prd1.log", 512);
    defer orchard.deinit();

    std.debug.print("Starting server\n", .{});
    const self_addr = try net.Address.resolveIp("0.0.0.0", 4206);
    var listener = try self_addr.listen(.{ .reuse_address = true });
    std.debug.print("Listening on {}\n", .{self_addr});

    while (listener.accept()) |conn| {
        std.debug.print("Accepted connection from: {}\n", .{conn.address});
        var recv_buf: [4096]u8 = undefined;
        var recv_total: usize = 0;
        while (conn.stream.read(recv_buf[recv_total..])) |recv_len| {
            if (recv_len == 0) break;
            recv_total += recv_len;
            if (mem.containsAtLeast(u8, recv_buf[0..recv_total], 1, "\r\n\r\n")) {
                break;
            }
        } else |read_err| {
            return read_err;
        }
        const recv_data = recv_buf[0..recv_total];
        if (recv_data.len == 0) {
            std.debug.print("Got connection but no header!\n", .{});
            continue;
        }

        const request: Request = try parseRaw(&recv_buf);
        const httpHead =
            "HTTP/1.1 200 OK \r\n" ++
            "Connection: close\r\n" ++
            "Content-Type: {s}\r\n" ++
            "Content-Length: {}\r\n" ++
            "\r\n";
        _ = try conn.stream.writer().print(httpHead, .{ "text", request.length });
        if (std.mem.eql(u8, request.operation, "PUT")) {
            _ = try conn.stream.writer().print("{s} {s} {s}\n", .{ request.operation, request.key, request.value.? });
        } else {
            _ = try conn.stream.writer().print("{s} {s} {any}\n", .{ request.operation, request.key, request.value });
        }

        // TODO: Perform PUT and GET operations on OrchardDB from the server
        _ = conn.stream.close();
    } else |err| {
        std.debug.print("error in accept: {}\n", .{err});
    }
}

pub const Request = struct {
    method: []const u8,
    path: []const u8,
    operation: []const u8,
    key: []const u8,
    value: ?[]const u8,
    length: usize,
};
pub fn parseRaw(buffer: []const u8) !Request {
    var len: usize = 3;
    var Header = std.mem.tokenizeSequence(u8, buffer, "\r\n");
    const requestLine = Header.next() orelse return error.MalformedRequest;
    var requestIter = std.mem.tokenizeScalar(u8, requestLine, ' ');
    var request: Request = undefined;
    const method = requestIter.next().?;
    if (!mem.eql(u8, method, "GET")) return error.MethodNotGET;
    request.method = method;
    request.path = requestIter.next() orelse return error.MalformedPath;
    if (std.mem.eql(u8, request.path[0..4], "/put")) {
        request.operation = "PUT";
        var pairs = mem.splitScalar(u8, request.path[5..], '=');
        request.key = pairs.next() orelse return error.KeyNotFound;
        request.value = pairs.next() orelse return error.ValueNotFound;
        len += request.key.len + request.value.?.len;
    } else if (std.mem.eql(u8, request.path[0..4], "/get")) {
        request.operation = "GET";
        request.key = request.path[5..];
        request.value = null;
        len += request.key.len;
    } else {
        return error.InvalidOperation;
    }
    return request;
}

test "OrchardDB" {
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
