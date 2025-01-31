const std = @import("std");
const Divisor = @import("quickdiv.zig").Divisor(u64);

/// Compute index for given hashed key.
pub fn getIndex(key_hash: u64, pilot_hash: u64, codomain_len: Divisor) usize {
    return codomain_len.remOf(key_hash ^ pilot_hash);
}

/// Compute bucket for given hashed key.
pub fn getBucket(key_hash: u64, buckets: Divisor) usize {
    return buckets.remOf(key_hash);
}

/// Hash given key with WyHash fast non-cryptographic hash function.
pub fn hashKey(key: anytype, seed: u64) u64 {
    return std.hash.Wyhash.hash(seed, std.mem.asBytes(&key));
}

/// Hash given pilot value with FxHash fast 8-byte non-cryptographic hash function.
pub fn hashPilotValue(pilot_value: u16) u64 {
    return @as(u64, pilot_value) *% 0x517CC1B727220A95;
}
