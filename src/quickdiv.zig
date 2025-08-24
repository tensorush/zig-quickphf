const std = @import("std");

/// Unsigned divisor optimized for repeated division and modulo operations.
pub fn Divisor(comptime T: type) type {
    if (std.meta.activeTag(@typeInfo(T)) != .int or
        @typeInfo(T).int.signedness != .unsigned or
        !std.math.isPowerOfTwo(@typeInfo(T).int.bits))
    {
        @compileError("Unsupported type: " ++ @typeName(T));
    }

    const W = @Type(.{ .int = .{ .signedness = .unsigned, .bits = 2 * @typeInfo(T).int.bits } });

    return struct {
        const Self = @This();

        const Kind = enum {
            MultiplyAddShift,
            MultiplyShift,
            Shift,
        };

        magic: T = undefined,
        divisor: T,
        kind: Kind,
        shift: u8,

        /// Construct divisor.
        pub fn init(divisor: T) Self {
            if (divisor == 0) {
                @panic("Divisor cannot be zero!");
            }

            const shift = std.math.log2_int(T, divisor);
            if (std.math.isPowerOfTwo(divisor)) {
                return .{ .kind = .Shift, .divisor = divisor, .shift = shift };
            } else {
                const res = Self.divRem(@as(T, 1) << shift, divisor);
                var magic = res.@"0";
                const rem = res.@"1";
                const e = divisor - rem;
                if (e < @as(T, 1) << shift) {
                    return .{ .kind = .MultiplyShift, .divisor = divisor, .magic = magic + 1, .shift = shift };
                } else {
                    magic *%= 2;
                    const doubled_rem = @mulWithOverflow(rem, 2);
                    if (doubled_rem.@"0" >= divisor or doubled_rem.@"1" == 1) {
                        magic += 1;
                    }
                    return .{ .kind = .MultiplyAddShift, .divisor = divisor, .magic = magic + 1, .shift = shift };
                }
            }
        }

        /// Compute remainder of dividing `num` by `self.divisor`.
        pub fn remOf(self: Self, num: T) T {
            return num - self.divisor * self.divOf(num);
        }

        /// Compute result of dividing `num` by `self.divisor`.
        pub fn divOf(self: Self, num: T) T {
            return switch (self.kind) {
                .Shift => num >> @intCast(self.shift),
                .MultiplyShift => Self.mulh(self.magic, num) >> @intCast(self.shift),
                .MultiplyAddShift => blk: {
                    const quot = Self.mulh(self.magic, num);
                    break :blk (((num - quot) >> 1) + quot) >> @intCast(self.shift);
                },
            };
        }

        /// Multiply two words together, returning product's top half.
        pub fn mulh(x: T, y: T) T {
            return @intCast((@as(W, x) * @as(W, y)) >> @typeInfo(T).int.bits);
        }

        /// Divide 2N-bit dividend by N-bit divisor with remainder.
        pub fn divRem(top_half: T, divisor: T) struct { T, T } {
            const num = @as(W, top_half) << @typeInfo(T).int.bits;
            return .{ @intCast(num / @as(W, divisor)), @intCast(num % @as(W, divisor)) };
        }

        test Self {
            var prng: std.Random.DefaultPrng = .init(blk: {
                var seed: u64 = undefined;
                try std.posix.getrandom(std.mem.asBytes(&seed));
                break :blk seed;
            });
            const random = prng.random();

            for (1..100_000) |_| {
                const num = random.intRangeAtMost(T, 1, std.math.maxInt(T));
                const div: Self = .init(random.intRangeAtMost(T, 1, std.math.maxInt(T)));

                try std.testing.expectEqual(num / div.divisor, div.divOf(num));
                try std.testing.expectEqual(num % div.divisor, div.remOf(num));
                try std.testing.expectEqual((div.divisor *% div.divOf(num)) + div.remOf(num), num);
            }
        }
    };
}
