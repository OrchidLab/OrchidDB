![OrchardDB_Dark_V1_Banner](https://github.com/user-attachments/assets/e8132d95-b148-4048-a662-0037e2fea008)

## Architecture

- HashMap: Bespoke hashmap optimised for atomic rapid transactions of key-value byte strings with timestamp support
- OrchardDB: Managed HashMap Object

## Todo

- [ ] WAL support
  - [X] write to wal
  - [ ] recover method
- [ ] Actual TCP Server to host OrchardDB
- [ ] ACID support
- [ ] Range queries (timestamp)
- [ ] Sharding
- [ ] Implement atomic operations and basic transaction support
- [ ] Add data expiration and automatic cleanup of expired entries
- [ ] Implement a robust error handling system throughout the codebase
- [ ] Implement a basic compaction process to reclaim space from deleted entries
- [ ] Add support for range queries and iteration over key-value pairs
- [ ] Implement a simple in-memory cache for frequently accessed items
- [ ] Add basic data validation and sanitization for inputs
- [ ] Implement a configurable consistency model (e.g., eventual, strong)
- [ ] Add support for batch operations to improve performance for multiple writes
- [ ] More complex data types ? (Learn from DenoKV)


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

