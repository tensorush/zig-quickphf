const std = @import("std");

const MAX_BUF_SIZE = 1 << 12;

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
            return .{ .phf = .init(keys), .vals = vals, .keys = keys };
        }

        /// Generate source file at given path containing hash map with given name.
        pub fn generate(self: Self, path: []const u8, name: []const u8) (std.fs.File.OpenError || std.io.Writer.Error)!void {
            var out_file = try std.fs.cwd().createFile(path, .{});
            defer out_file.close();

            var out_file_buf: [MAX_BUF_SIZE]u8 = undefined;
            var out_file_writer = out_file.writer(&out_file_buf);
            const writer = &out_file_writer.interface;

            try writer.writeAll("//! Static hash map generated with `quickphf`:\n//! https://github.com/tensorush/zig-quickphf\n\n");
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
            for (&self.phf.map) |idx| {
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

            try writer.flush();
        }
    };
}
