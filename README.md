# Robust and maintanable distributed key-value store written in Zig

## Architecture

- HashMap: Bespoke hashmap optimised for atomic rapid transactions of key-value byte strings with timestamp support
- OrchardDB: Managed HashMap Object

## Todo

- Add WAL support
- Full ACID support
- timestamp (range queries)
- sharding

## Usage

```
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = allocator.allocator();
    var orchard = try OrchardDB.init(gpa, "./.orchard.1.db");
    defer orchard.deinit();

    var buffer: [5]u8 = undefined;
    for (48..128) |char| {
        const ch: u8 = @intCast(char);
        const key = try std.fmt.bufPrint(&buffer, "key_{c}", .{ch});
        try orchard.put(key, &[_]u8{ch});
    }

```

```
key_R R 1720933912
key__ _ 1720933912
key_X X 1720933912
key_E E 1720933912
key_N N 1720933912
key_K K 1720933912
key_4 4 1720933912
key_1 1 1720933912
key_: : 1720933912
key_g g 1720933912
key_` ` 1720933912
key_m m 1720933912
key_V V 1720933912
key_S S 1720933912
key_\ \ 1720933912
key_Y Y 1720933912
key_B B 1720933912
key_O O 1720933912
key_H H 1720933912
...

```
