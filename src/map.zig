const std = @import("std");
const utils = @import("utils.zig");
const quickdiv = @import("quickdiv");

pub fn Map(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        const Entry = struct {
            key: K,
            val: V,
        };

        raw_map: RawMap(K, Entry),

        pub fn init(seed: u64, pilot_table: []const u16, entries: []const Entry, free_slots: []const u32) Self {
            return .{ .raw_map = RawMap(K, Entry).init(seed, pilot_table, entries, free_slots) };
        }

        pub fn contains(self: Self, key: K) bool {
            return if (self.getItemPtr(key)) |_| true else false;
        }

        pub fn getPtr(self: Self, key: K) ?*const V {
            return if (self.getItemPtr(key)) |item| &item.val else null;
        }

        pub fn getKeyPtr(self: Self, key: K) ?*const K {
            return if (self.getItemPtr(key)) |item| &item.key else null;
        }

        pub fn getItemPtr(self: Self, key: K) ?*const Entry {
            const item = self.raw_map.getPtr(key);
            return if (std.mem.eql(u8, std.mem.asBytes(&item.key), std.mem.asBytes(&key))) item else null;
        }
    };
}

fn RawMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        codomain_len: quickdiv.DivisorU64,
        buckets: quickdiv.DivisorU64,
        pilot_table: []const u16,
        free_slots: []const u32,
        values: []const V,
        seed: u64,

        pub fn init(seed: u64, pilot_table: []const u16, values: []const V, free_slots: []const u32) Self {
            return .{
                .codomain_len = quickdiv.DivisorU64.init(@intCast(values.len + free_slots.len)),
                .buckets = quickdiv.DivisorU64.init(@intCast((pilot_table.len))),
                .pilot_table = pilot_table,
                .values = values,
                .free_slots = free_slots,
                .seed = seed,
            };
        }

        pub fn getPtr(self: Self, key: K) *const V {
            const key_hash = utils.hashKey(key, self.seed);
            const bucket = utils.getBucket(key_hash, self.buckets);
            const pilot_hash = utils.hashPilotValue(self.pilot_table[bucket]);
            const idx = utils.getIndex(key_hash, pilot_hash, self.codomain_len);
            return if (idx < self.values.len) &self.values[idx] else &self.values[self.free_slots[idx - self.values.len]];
        }
    };
}
