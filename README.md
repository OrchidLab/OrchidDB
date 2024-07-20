![OrchardDB_Dark_V1_Banner](https://github.com/user-attachments/assets/e8132d95-b148-4048-a662-0037e2fea008)

## TCP Server Usage
```
>> zig build run
>> Starting server
>> Listening on 0.0.0.0:4206
>> Accepted connection from: 127.0.0.1:54245
>> curl "127.0.0.1:4206/put?key2=baz"
>> [INFO] (PUT) KEY: key2 VALUE: baz
>> curl "127.0.0.1:4206/put?key100=bar"
>> [INFO] (PUT) KEY: key100 VALUE: bar
>> curl "127.0.0.1:4206/put?key200=foor"
>> [INFO] (PUT) KEY: key200 VALUE: foor
>> curl "127.0.0.1:4206/get/key2"
>> [INFO] (GET) KEY: key2 VALUE: baz
>> curl "127.0.0.1:4206/delete/key2"
>> [INFO] (DELETE) KEY: key2
```

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

- [X] ~ **CRITICAL** Refactor to a Config struct
  - [X] Create a configuration structure to manage various database options
  - [X] Include options for persistence settings, etc.
  - [ ] TTL options?
  - [X] Make the database more flexible and easier to configure

- [x] TCP Server Implementation
  - [x] Create a working TCP server to handle client connections
  - [x] Implement /PUT and /GET operations over the network
  - [x] Integrate OrchardDB instance with the TCP server

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

## References

- https://ziglang.org/documentation/master
- https://www.pedaldrivenprogramming.com/2024/03/writing-a-http-server-in-zig/
- https://github.com/jetzig-framework/jetkv

<hr>
![ssshape(2)](https://github.com/user-attachments/assets/fe8719dc-ca20-4adb-b56c-55d4fa562a39)



<img style="margin-top: 50px; width:150px; float:right;" src="https://humanmademark.com/black-logo.png" alt="Human Made Trademark"></img>

<img style="width:150px; float:right;" src="https://humanmademark.com/white-logo.png" alt="Human Made Trademark"></img>
