const std = @import("std");
const utils = @import("utils.zig");
const quickdiv = @import("quickdiv");

const MIN_COEF: f64 = 1.5;
const MAX_ALPHA: f64 = 0.99;

const HashedEntry = struct {
    bucket: usize,
    idx: usize,
    hash: u64,

    pub fn lessThan(_: void, lhs: HashedEntry, rhs: HashedEntry) bool {
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

const NewEntry = struct {
    dest_idx: usize,
    idx: usize,

    pub fn lessThan(_: void, lhs: NewEntry, rhs: NewEntry) bool {
        return lhs.dest_idx < rhs.dest_idx;
    }
};

pub fn Phf(comptime E: type, comptime NUM_ENTRIES: u64) type {
    const EMPTY_ENTRY = std.math.maxInt(u32);
    if (NUM_ENTRIES == 0 or NUM_ENTRIES >= EMPTY_ENTRY) {
        @compileError("Invalid number of entries!");
    }

    const LOG_NUM_ENTRIES = std.math.log2_int(u64, NUM_ENTRIES);

    const COEF = MIN_COEF + 0.2 * @as(f64, LOG_NUM_ENTRIES);
    const NUM_BUCKETS: u64 = if (NUM_ENTRIES > 1) @ceil(COEF * @as(f64, NUM_ENTRIES) / LOG_NUM_ENTRIES) else 1;

    const ALPHA = MAX_ALPHA - 0.001 * @as(f64, LOG_NUM_ENTRIES);
    const CANDIDATE: u64 = @ceil(@as(f64, NUM_ENTRIES) / ALPHA);
    const CODOMAIN_SIZE = CANDIDATE + (1 - CANDIDATE % 2);
    const NUM_EXTRA_SLOTS = CODOMAIN_SIZE - NUM_ENTRIES;

    return struct {
        const Self = @This();

        free_slots: [NUM_EXTRA_SLOTS]u32,
        pilot_table: [NUM_BUCKETS]u16,
        map: [NUM_ENTRIES]u32,
        seed: u64,

        pub fn init(entries: *const [NUM_ENTRIES]E) Self {
            const codomain_len = quickdiv.DivisorU64.init(CODOMAIN_SIZE);
            const num_buckets = quickdiv.DivisorU64.init(NUM_BUCKETS);
            var cur_entry: u64 = 1;
            outer: while (cur_entry <= EMPTY_ENTRY) : (cur_entry += 1) {
                const seed = cur_entry << 32;
                var hashed_entries: [NUM_ENTRIES]HashedEntry = undefined;
                for (entries[0..], 0..) |entry, idx| {
                    const hash = utils.hashKey(entry, seed);
                    const bucket = utils.getBucket(hash, num_buckets);
                    hashed_entries[idx] = .{ .bucket = bucket, .hash = hash, .idx = idx };
                }
                std.sort.pdq(HashedEntry, hashed_entries[0..], {}, HashedEntry.lessThan);

                for (hashed_entries[0 .. NUM_ENTRIES - 1], hashed_entries[1..]) |e0, e1| {
                    if (e0.hash == e1.hash and e0.bucket == e1.bucket) {
                        if (entries[e0.idx] == entries[e1.idx]) {
                            @panic("Found duplicate keys!");
                        }
                        continue :outer;
                    }
                }

                var buckets: [NUM_BUCKETS]BucketData = undefined;
                var start_idx: usize = 0;
                for (buckets[0..], 0..) |*bucket, idx| {
                    var size: usize = 0;
                    for (hashed_entries[start_idx..]) |hashed_entry| {
                        if (hashed_entry.bucket != idx) {
                            break;
                        }
                        size += 1;
                    }
                    bucket.* = .{ .start_idx = start_idx, .size = size, .idx = idx };
                    start_idx += size;
                }
                std.sort.pdq(BucketData, buckets[0..], {}, BucketData.lessThan);

                var co_map = [1]u32{EMPTY_ENTRY} ** CODOMAIN_SIZE;
                var pilot_table = [1]u16{0} ** NUM_BUCKETS;
                for (buckets) |bucket| {
                    const bucket_entries = hashed_entries[bucket.start_idx .. bucket.start_idx + bucket.size];
                    var is_pilot_found = false;
                    var pilot: u16 = 0;
                    outer_pilot: while (pilot <= std.math.maxInt(u16)) : (pilot += 1) {
                        var new_entries: [NUM_ENTRIES]NewEntry = undefined;
                        const pilot_hash = utils.hashPilotValue(pilot);
                        var num_new_entries: usize = 0;
                        for (bucket_entries) |bucket_entry| {
                            const dest_idx = utils.getIndex(bucket_entry.hash, pilot_hash, codomain_len);
                            if (co_map[dest_idx] != EMPTY_ENTRY) {
                                continue :outer_pilot;
                            }
                            new_entries[num_new_entries] = .{ .idx = bucket_entry.idx, .dest_idx = dest_idx };
                            num_new_entries += 1;
                        }
                        std.sort.pdq(NewEntry, new_entries[0..num_new_entries], {}, NewEntry.lessThan);

                        if (num_new_entries > 0) {
                            for (new_entries[0 .. num_new_entries - 1], new_entries[1..num_new_entries]) |e0, e1| {
                                if (e0.dest_idx == e1.dest_idx) {
                                    continue :outer_pilot;
                                }
                            }
                        }

                        is_pilot_found = true;
                        for (new_entries[0..num_new_entries]) |new_entry| {
                            co_map[new_entry.dest_idx] = @intCast(new_entry.idx);
                        }
                        pilot_table[bucket.idx] = pilot;

                        break;
                    }

                    if (!is_pilot_found) {
                        continue :outer;
                    }
                }

                var free_slots = [1]u32{0} ** NUM_EXTRA_SLOTS;
                var back_idx = NUM_ENTRIES;
                var front_idx: u32 = 0;
                while (front_idx < NUM_ENTRIES) : (front_idx += 1) {
                    if (co_map[front_idx] != EMPTY_ENTRY) {
                        continue;
                    }
                    while (co_map[back_idx] == EMPTY_ENTRY) {
                        back_idx += 1;
                    }
                    co_map[front_idx] = co_map[back_idx];
                    free_slots[back_idx - NUM_ENTRIES] = front_idx;
                    back_idx += 1;
                }

                var map: [NUM_ENTRIES]u32 = undefined;
                @memcpy(map[0..], co_map[0..NUM_ENTRIES]);
                return .{ .pilot_table = pilot_table, .free_slots = free_slots, .seed = seed, .map = map };
            }

            unreachable;
        }
    };
}
