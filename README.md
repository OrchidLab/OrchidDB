![OrchardDB_Dark_V1_Banner](https://github.com/user-attachments/assets/e8132d95-b148-4048-a662-0037e2fea008)

## Architecture

- HashMap: Bespoke hashmap optimised for atomic rapid transactions of key-value byte strings with timestamp support
- OrchardDB: Managed HashMap Object

## Todo

- [x] Basic Operations
  - [x] PUT: Insert or update a key-value pair
  - [x] GET: Retrieve a value by its key
  - [x] DELETE: Remove a key-value pair

- [x] Write-Ahead Logging (WAL) Support
  - [x] Write operations to WAL: Ensures durability by logging operations before applying them
  - [x] Implement recovery method: Allows database restoration from WAL in case of crashes

- [ ] **CRITICAL** Refactor to a Config struct
  - [ ] Create a configuration structure to manage various database options
  - [ ] Include options for TTL (Time-To-Live), persistence settings, etc.
  - [ ] Make the database more flexible and easier to configure

- [x] TCP Server Implementation
  - [x] Create a working TCP server to handle client connections
  - [x] Implement /PUT and /GET operations over the network
  - [x] Integrate OrchardDB instance with the TCP server

- [ ] REPL
  - [X] Basic REPL implementation
  - [ ] Enum matching
  - [ ] Ergonomic repl

- [ ] **CRITICAL** Batch Operations
  - [ ] Allow multiple operations to be performed in a single request
  - [ ] Improve efficiency for bulk inserts or updates
  - [ ] Reduce network overhead for clients performing multiple operations

- [ ] TTL/Key Expiration
  - [ ] Implement automatic expiration of keys based on a set time-to-live
  - [ ] Include a cleanup mechanism to remove expired entries

- [ ] Range Queries
  - [ ] Allow querying for a range of keys based on their version or other criteria
  - [ ] Implement functionality for time-based or sequential data retrieval

- [ ] HashMap Iterator Interface
  - [ ] Provide a way to iterate over the HashMap entries
  - [ ] Create utility functions for operations that need to process all data

- [ ] **CRITICAL** ACID Support
  - [ ] Implement Atomicity, Consistency, Isolation, and Durability properties
  - [ ] Include basic transaction support for multi-key operations
  - [ ] Ensure data integrity in concurrent environments

- [ ] Sharding
  - [ ] Distribute data across multiple nodes to improve scalability
  - [ ] Implement a sharding strategy (e.g., range-based, hash-based)

- [ ] Compaction Process
  - [ ] Implement a mechanism to reclaim space from deleted or expired entries
  - [ ] Improve storage efficiency over time

- [ ] In-Memory Cache
  - [ ] Add a caching layer for frequently accessed items
  - [ ] Improve read performance for hot data

- [ ] Data Validation and Sanitization
  - [ ] Implement input checks to ensure data integrity
  - [ ] Prevent potential security issues from malformed inputs

- [ ] Support for Different Data Types
  - [ ] Extend beyond simple string key-value pairs
  - [ ] Consider supporting integers, floats, lists, or even JSON objects

- [ ] Authentication and Authorization
  - [ ] Implement user authentication for secure access
  - [ ] Add role-based access control for different operations

- [ ] Analytics Features
  - [ ] Add logging and metrics collection
  - [ ] Provide insights into database usage and performance

- [ ] Configurable Consistency Model
  - [ ] Allow users to choose between consistency levels (e.g., eventual, strong)
  - [ ] Implement mechanisms for tuning performance vs. consistency trade-offs

- [ ] Advanced Data Structures
  - [ ] Research and potentially implement more complex data types
  - [ ] Look into DenoKV for inspiration on advanced features

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


#### Code is Human Made 
<img style="width:150px; float:right;" src="https://humanmademark.com/black-logo.png" alt="Human Made Trademark"></img>

<img style="width:150px; float:right;" src="https://humanmademark.com/white-logo.png" alt="Human Made Trademark"></img>
