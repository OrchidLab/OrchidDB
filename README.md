![OrchardDB_Dark_V1_Banner](https://github.com/user-attachments/assets/e8132d95-b148-4048-a662-0037e2fea008)

## Architecture

- HashMap: Bespoke hashmap optimised for atomic rapid transactions of key-value byte strings with timestamp support
- OrchardDB: Managed HashMap Object

## Todo

- [X] PUT, GET, DELETE
- [X] WAL support
  - [X] write to wal
  - [X] recover method
- [ ] Refactor to a Config .{} struct for extended optiosn (TTL, Persistance)
- [ ] Actual TCP Server to host OrchardDB
  - [X] Working TCP Server to handle /PUT and /GET operations
  - [ ] PUT and GET direct the OrchardDB instance
- [ ] Batch Operations
- [ ] TTL/Key experiation
- [ ] Range queries (on version)
- [ ] Optional, HashMap Iterator interface
- [ ] Add data expiration and automatic cleanup of expired entries
- [ ] ACID support
  - [ ] Implement atomic operations and basic transaction support
- [ ] Sharding
- [ ] Implement a basic compaction process to reclaim space from deleted entries
- [ ] Implement a simple in-memory cache for frequently accessed items
- [ ] Add basic data validation and sanitization for inputs
- [ ] Different data types
- [ ] Auth
- [ ] Analytics
- [ ] Implement a configurable consistency model (e.g., eventual, strong)
- [ ] More complex data types ? (Learn from DenoKV)


## Usage


Adding 4094 items, while deleting a key every 100 items
```
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

```

*.db
```
  ...
  KEY979 VAL979 1720999218
  KEY270 VAL270 1720999218
  KEY172 VAL172 1720999218
  KEY144 VAL144 1720999218
  KEY487 VAL487 1720999218
  KEY734 VAL734 1720999218
  KEY742 VAL742 1720999218
  KEY23 VAL23 1720999218
  KEY218 VAL218 1720999218
  KEY524 VAL524 1720999218
  KEY231 VAL231 1720999218
  KEY434 VAL434 1720999218
  KEY603 VAL603 1720999218
  KEY714 VAL714 1720999218
  KEY1006 VAL1006 1720999218
  KEY694 VAL694 1720999218
  KEY62 VAL62 1720999218
  KEY379 VAL379 1720999218
  KEY576 VAL576 1720999218
  KEY642 VAL642 1720999218
  KEY803 VAL803 1720999218
  KEY106 VAL106 1720999218
  KEY19 VAL19 1720999218
  KEY183 VAL183 1720999218
  KEY639 VAL639 1720999218
  ...
```

*.log
```
  ...
  PUT KEY3789 VAL3789
  PUT KEY3790 VAL3790
  PUT KEY3791 VAL3791
  PUT KEY3792 VAL3792
  PUT KEY3793 VAL3793
  PUT KEY3794 VAL3794
  PUT KEY3795 VAL3795
  PUT KEY3796 VAL3796
  PUT KEY3797 VAL3797
  PUT KEY3798 VAL3798
  PUT KEY3799 VAL3799
  DELETE KEY3799 
  PUT KEY3801 VAL3801
  PUT KEY3802 VAL3802
  PUT KEY3803 VAL3803
  PUT KEY3804 VAL3804
  PUT KEY3805 VAL3805
  PUT KEY3806 VAL3806
  PUT KEY3807 VAL3807
  PUT KEY3808 VAL3808
  PUT KEY3809 VAL3809
  PUT KEY3810 VAL3810
  PUT KEY3811 VAL3811
  PUT KEY3812 VAL3812
  PUT KEY3813 VAL3813
  PUT KEY3814 VAL3814
  PUT KEY3815 VAL3815
  PUT KEY3816 VAL3816
  PUT KEY3817 VAL3817
  ...
```


<img style="width:150px; float:right;" src="https://humanmademark.com/black-logo.png" alt="Human Made Trademark"></img>

<img style="width:150px; float:right;" src="https://humanmademark.com/white-logo.png" alt="Human Made Trademark"></img>
