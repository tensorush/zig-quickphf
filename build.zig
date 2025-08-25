const std = @import("std");

const manifest = @import("build.zig.zon");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/root.zig");
    const version: std.SemanticVersion = try .parse(manifest.version);

    // Public root module
    const root_mod = b.addModule("quickphf", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
        .strip = b.option(bool, "strip", "Strip the binary"),
    });

    // Library
    const lib = b.addLibrary(.{
        .name = "quickphf",
        .version = version,
        .root_module = root_mod,
    });
    b.installArtifact(lib);

    // Documentation
    const docs_step = b.step("doc", "Emit documentation");

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);

    // Example
    const example_step = b.step("example", "Run example");

    const example_exe = b.addExecutable(.{
        .name = "example",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path(EXAMPLE_DIR ++ "main.zig"),
            .imports = &.{
                .{ .name = "quickphf", .module = root_mod },
            },
        }),
    });

    const example_exe_run = b.addRunArtifact(example_exe);
    example_step.dependOn(&example_exe_run.step);

    // Formatting check
    const fmt_step = b.step("fmt", "Check formatting");

    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
            "build.zig.zon",
            EXAMPLE_DIR,
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    install_step.dependOn(fmt_step);

    // Compilation check for ZLS Build-On-Save
    // See: https://zigtools.org/zls/guides/build-on-save/
    const check_step = b.step("check", "Check compilation");
    const check_exe = b.addExecutable(.{
        .name = "quickphf",
        .version = version,
        .root_module = root_mod,
    });
    check_step.dependOn(&check_exe.step);
}

const EXAMPLE_DIR = "example/";
