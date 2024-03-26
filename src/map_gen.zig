const std = @import("std");
const Phf = @import("phf.zig").Phf;

/// Static minimal perfect hash map code generator.
pub fn MapGen(comptime K: type, comptime V: type, comptime NUM_ENTRIES: u64) type {
    return struct {
        const Self = @This();

        keys: *const [NUM_ENTRIES]K,
        vals: *const [NUM_ENTRIES]V,
        phf: Phf(K, NUM_ENTRIES),

        /// Initialize code generator.
        pub fn init(keys: *const [NUM_ENTRIES]K, vals: *const [NUM_ENTRIES]V) Self {
            return .{ .phf = Phf(K, NUM_ENTRIES).init(keys), .vals = vals, .keys = keys };
        }

        /// Generate source file at given path containing hash map with given name.
        pub fn generate(self: Self, path: []const u8, name: []const u8) !void {
            var file = try std.fs.cwd().createFile(path, .{});
            defer file.close();

            var buf_writer = std.io.bufferedWriter(file.writer());
            const writer = buf_writer.writer();

            try writer.writeAll("//! Static hash map generated with [QuickPhf](https://github.com/tensorush/zig-quickphf).\n\n");
            try writer.writeAll("const quickphf = @import(\"quickphf\");\n\n");
            try writer.print("pub const {s} = quickphf.Map({s}, {s}).init(\n", .{ name, @typeName(K), @typeName(V) });
            try writer.print("    {d},\n", .{self.phf.seed});

            if (self.phf.pilot_table.len == 1) {
                try writer.writeAll("    &.{");
                try writer.print("{d}", .{self.phf.pilot_table[0]});
                try writer.writeAll("},\n");
            } else {
                try writer.writeAll("    &.{ ");
                try writer.print("{d}", .{self.phf.pilot_table[0]});
                for (self.phf.pilot_table[1..]) |entry| {
                    try writer.print(", {d}", .{entry});
                }
                try writer.writeAll(" },\n");
            }

            try writer.writeAll("    &.{\n");
            for (self.phf.map[0..]) |idx| {
                try writer.writeAll("        .{ ");
                try writer.print(".key = {any}, .val = {any}", .{ self.keys[idx], self.vals[idx] });
                try writer.writeAll(" },\n");
            }
            try writer.writeAll("    },\n");

            if (self.phf.free_slots.len == 1) {
                try writer.writeAll("    &.{");
                try writer.print("{d}", .{self.phf.free_slots[0]});
                try writer.writeAll("},\n);\n");
            } else {
                try writer.writeAll("    &.{ ");
                try writer.print("{d}", .{self.phf.free_slots[0]});
                for (self.phf.free_slots[1..]) |entry| {
                    try writer.print(", {d}", .{entry});
                }
                try writer.writeAll(" },\n);\n");
            }

            try buf_writer.flush();
        }
    };
}
