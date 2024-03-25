//! Static hash map generated with [QuickPhf](https://github.com/tensorush/zig-quickphf).

const quickphf = @import("quickphf");

pub const FOURTH_POWERS_TO_ROOTS_MAP = quickphf.Map(u32, u32).init(
    4294967296,
    &.{ 0, 0, 0, 0, 13, 1, 4 },
    &.{
        .{ .key = 16, .val = 2 },
        .{ .key = 6561, .val = 9 },
        .{ .key = 81, .val = 3 },
        .{ .key = 4096, .val = 8 },
        .{ .key = 10000, .val = 10 },
        .{ .key = 1, .val = 1 },
        .{ .key = 1296, .val = 6 },
        .{ .key = 625, .val = 5 },
        .{ .key = 2401, .val = 7 },
        .{ .key = 256, .val = 4 },
    },
    &.{5},
);
