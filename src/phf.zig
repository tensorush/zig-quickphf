const std = @import("std");
const utils = @import("utils.zig");
const Divisor = @import("quickdiv.zig").Divisor(u64);

const MIN_COEF: f64 = 1.5;
const MAX_ALPHA: f64 = 0.99;

const HashedKey = struct {
    bucket: usize,
    idx: usize,
    hash: u64,

    pub fn lessThan(_: void, lhs: HashedKey, rhs: HashedKey) bool {
        return lhs.bucket < rhs.bucket or (lhs.bucket == rhs.bucket and lhs.hash < rhs.hash);
    }
};

const BucketData = struct {
    start_idx: usize,
    size: usize,
    idx: usize,

    pub fn lessThan(_: void, lhs: BucketData, rhs: BucketData) bool {
        return lhs.size > rhs.size;
    }
};

const NewKey = struct {
    dest_idx: usize,
    idx: usize,

    pub fn lessThan(_: void, lhs: NewKey, rhs: NewKey) bool {
        return lhs.dest_idx < rhs.dest_idx;
    }
};

/// Minimal perfect hash function with improved PTHash algorithm based on given keys.
pub fn Phf(comptime K: type, comptime NUM_KEYS: u64) type {
    const EMPTY_KEY = std.math.maxInt(u32);
    if (NUM_KEYS == 0 or NUM_KEYS >= EMPTY_KEY) {
        @compileError("Invalid number of keys!");
    }

    const LOG_NUM_KEYS = std.math.log2_int(u64, NUM_KEYS);

    const COEF = MIN_COEF + 0.2 * @as(f64, LOG_NUM_KEYS);
    const NUM_BUCKETS: u64 = if (NUM_KEYS > 1) @ceil(COEF * @as(f64, NUM_KEYS) / LOG_NUM_KEYS) else 1;

    const ALPHA = MAX_ALPHA - 0.001 * @as(f64, LOG_NUM_KEYS);
    const CANDIDATE: u64 = @ceil(@as(f64, NUM_KEYS) / ALPHA);
    const CODOMAIN_SIZE = CANDIDATE + (1 - CANDIDATE % 2);
    const NUM_EXTRA_SLOTS = CODOMAIN_SIZE - NUM_KEYS;

    return struct {
        const Self = @This();

        free_slots: [NUM_EXTRA_SLOTS]u32,
        pilot_table: [NUM_BUCKETS]u16,
        map: [NUM_KEYS]u32,
        seed: u64,

        /// Initialize minimal perfect hash function.
        pub fn init(keys: *const [NUM_KEYS]K) Self {
            const codomain_len = Divisor.init(CODOMAIN_SIZE);
            const num_buckets = Divisor.init(NUM_BUCKETS);
            var cur_key: u64 = 1;
            outer: while (cur_key <= EMPTY_KEY) : (cur_key += 1) {
                const seed = cur_key << 32;
                var hashed_keys: [NUM_KEYS]HashedKey = undefined;
                for (keys[0..], 0..) |key, idx| {
                    const hash = utils.hashKey(key, seed);
                    const bucket = utils.getBucket(hash, num_buckets);
                    hashed_keys[idx] = .{ .bucket = bucket, .hash = hash, .idx = idx };
                }
                std.sort.pdq(HashedKey, hashed_keys[0..], {}, HashedKey.lessThan);

                for (hashed_keys[0 .. NUM_KEYS - 1], hashed_keys[1..]) |e0, e1| {
                    if (e0.hash == e1.hash and e0.bucket == e1.bucket) {
                        if (keys[e0.idx] == keys[e1.idx]) {
                            @panic("Found duplicate keys!");
                        }
                        continue :outer;
                    }
                }

                var buckets: [NUM_BUCKETS]BucketData = undefined;
                var start_idx: usize = 0;
                for (buckets[0..], 0..) |*bucket, idx| {
                    var size: usize = 0;
                    for (hashed_keys[start_idx..]) |hashed_key| {
                        if (hashed_key.bucket != idx) {
                            break;
                        }
                        size += 1;
                    }
                    bucket.* = .{ .start_idx = start_idx, .size = size, .idx = idx };
                    start_idx += size;
                }
                std.sort.pdq(BucketData, buckets[0..], {}, BucketData.lessThan);

                var co_map = [1]u32{EMPTY_KEY} ** CODOMAIN_SIZE;
                var pilot_table = [1]u16{0} ** NUM_BUCKETS;
                for (buckets) |bucket| {
                    const bucket_keys = hashed_keys[bucket.start_idx .. bucket.start_idx + bucket.size];
                    var is_pilot_found = false;
                    var pilot: u16 = 0;
                    outer_pilot: while (pilot <= std.math.maxInt(u16)) : (pilot += 1) {
                        var new_keys: [NUM_KEYS]NewKey = undefined;
                        const pilot_hash = utils.hashPilotValue(pilot);
                        var num_new_keys: usize = 0;
                        for (bucket_keys) |bucket_key| {
                            const dest_idx = utils.getIndex(bucket_key.hash, pilot_hash, codomain_len);
                            if (co_map[dest_idx] != EMPTY_KEY) {
                                continue :outer_pilot;
                            }
                            new_keys[num_new_keys] = .{ .idx = bucket_key.idx, .dest_idx = dest_idx };
                            num_new_keys += 1;
                        }
                        std.sort.pdq(NewKey, new_keys[0..num_new_keys], {}, NewKey.lessThan);

                        if (num_new_keys > 0) {
                            for (new_keys[0 .. num_new_keys - 1], new_keys[1..num_new_keys]) |e0, e1| {
                                if (e0.dest_idx == e1.dest_idx) {
                                    continue :outer_pilot;
                                }
                            }
                        }

                        is_pilot_found = true;
                        for (new_keys[0..num_new_keys]) |new_key| {
                            co_map[new_key.dest_idx] = @intCast(new_key.idx);
                        }
                        pilot_table[bucket.idx] = pilot;

                        break;
                    }

                    if (!is_pilot_found) {
                        continue :outer;
                    }
                }

                var free_slots = [1]u32{0} ** NUM_EXTRA_SLOTS;
                var back_idx = NUM_KEYS;
                var front_idx: u32 = 0;
                while (front_idx < NUM_KEYS) : (front_idx += 1) {
                    if (co_map[front_idx] != EMPTY_KEY) {
                        continue;
                    }
                    while (co_map[back_idx] == EMPTY_KEY) {
                        back_idx += 1;
                    }
                    co_map[front_idx] = co_map[back_idx];
                    free_slots[back_idx - NUM_KEYS] = front_idx;
                    back_idx += 1;
                }

                var map: [NUM_KEYS]u32 = undefined;
                @memcpy(map[0..], co_map[0..NUM_KEYS]);
                return .{ .pilot_table = pilot_table, .free_slots = free_slots, .seed = seed, .map = map };
            }

            unreachable;
        }
    };
}
