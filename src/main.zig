const repl = @import("repl.zig");
const tcp = @import("tcp.zig");
pub fn main() !void {
    _ = try repl.repl();
    // _ = try tcp.http();
}
