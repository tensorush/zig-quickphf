const quickphf = @import("quickphf");

pub fn main() !void {
    const keys = [_]u32{ 16, 6561, 81, 4096, 10000, 1, 1296, 625, 2401, 256 };
    const vals = [keys.len]u32{ 2, 9, 3, 8, 10, 1, 6, 5, 7, 4 };
    const map_gen = quickphf.MapGen(u32, u32, keys.len).init(&keys, &vals);

    try map_gen.generate("example/gen.zig", "FOURTH_POWERS_TO_ROOTS_MAP");
}
