const std = @import("std");

test {
    const FOURTH_POWERS_TO_ROOTS_MAP = @import("gen.zig").FOURTH_POWERS_TO_ROOTS_MAP;

    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(1).?.*, 1);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(16).?.*, 2);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(81).?.*, 3);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(256).?.*, 4);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(625).?.*, 5);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(1296).?.*, 6);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(2401).?.*, 7);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(4096).?.*, 8);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(6561).?.*, 9);
    try std.testing.expectEqual(FOURTH_POWERS_TO_ROOTS_MAP.getPtr(10000).?.*, 10);
}
