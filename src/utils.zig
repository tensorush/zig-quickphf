const std = @import("std");
const quickdiv = @import("quickdiv");

pub fn getIndex(key_hash: u64, pilot_hash: u64, codomain_len: quickdiv.DivisorU64) usize {
    return codomain_len.remOf(key_hash ^ pilot_hash);
}

pub fn getBucket(key_hash: u64, buckets: quickdiv.DivisorU64) usize {
    return buckets.remOf(key_hash);
}

pub fn hashKey(key: anytype, seed: u64) u64 {
    return std.hash.Wyhash.hash(seed, std.mem.asBytes(&key));
}

pub fn hashPilotValue(pilot_value: u16) u64 {
    return @as(u64, pilot_value) *% 0x517CC1B727220A95;
}
