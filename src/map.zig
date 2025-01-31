const std = @import("std");
const utils = @import("utils.zig");
const Divisor = @import("quickdiv.zig").Divisor(u64);

/// Static minimal perfect hash map that stores its keys.
pub fn Map(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        const Entry = struct {
            key: K,
            val: V,
        };

        raw_map: RawMap(K, Entry),

        /// Initialize map.
        pub fn init(seed: u64, pilot_table: []const u16, entries: []const Entry, free_slots: []const u32) Self {
            return .{ .raw_map = RawMap(K, Entry).init(seed, pilot_table, entries, free_slots) };
        }

        /// Check if the map contains given key.
        pub fn contains(self: Self, key: K) bool {
            return if (self.getEntryPtr(key)) |_| true else false;
        }

        /// Retrieve constant value pointer corresponding to given key, if present.
        pub fn getPtr(self: Self, key: K) ?*const V {
            return if (self.getEntryPtr(key)) |entry| &entry.val else null;
        }

        /// Retrieve constant key pointer corresponding to given key, if present.
        pub fn getKeyPtr(self: Self, key: K) ?*const K {
            return if (self.getEntryPtr(key)) |entry| &entry.key else null;
        }

        /// Retrieve constant entry pointer corresponding to given key, if present.
        pub fn getEntryPtr(self: Self, key: K) ?*const Entry {
            const entry = self.raw_map.getPtr(key);
            return if (std.mem.eql(u8, std.mem.asBytes(&entry.key), std.mem.asBytes(&key))) entry else null;
        }
    };
}

/// Static minimal perfect hash map that doesn't store its keys.
/// Not meant to be used directly.
fn RawMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        codomain_len: Divisor,
        buckets: Divisor,
        pilot_table: []const u16,
        free_slots: []const u32,
        values: []const V,
        seed: u64,

        /// Initialize raw map.
        pub fn init(seed: u64, pilot_table: []const u16, values: []const V, free_slots: []const u32) Self {
            return .{
                .codomain_len = Divisor.init(@intCast(values.len + free_slots.len)),
                .buckets = Divisor.init(@intCast((pilot_table.len))),
                .pilot_table = pilot_table,
                .values = values,
                .free_slots = free_slots,
                .seed = seed,
            };
        }

        /// Retrieve constant value pointer by given key, if present.
        /// Otherwise, return pointer to arbitrary free value.
        pub fn getPtr(self: Self, key: K) *const V {
            const key_hash = utils.hashKey(key, self.seed);
            const bucket = utils.getBucket(key_hash, self.buckets);
            const pilot_hash = utils.hashPilotValue(self.pilot_table[bucket]);
            const idx = utils.getIndex(key_hash, pilot_hash, self.codomain_len);
            return if (idx < self.values.len) &self.values[idx] else &self.values[self.free_slots[idx - self.values.len]];
        }
    };
}
