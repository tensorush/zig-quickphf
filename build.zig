const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/lib.zig");
    const version = std.SemanticVersion{ .major = 0, .minor = 2, .patch = 0 };

    // Module
    const quickphf_mod = b.addModule("quickphf", .{ .root_source_file = root_source_file });

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "quickphf",
        .target = target,
        .version = version,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Documentation
    const doc_step = b.step("doc", "Emit documentation");

    const doc_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "doc",
        .source_dir = lib.getEmittedDocs(),
    });
    doc_step.dependOn(&doc_install.step);
    b.default_step.dependOn(doc_step);

    // Example
    const example_step = b.step("example", "Run example");

    const example = b.addExecutable(.{
        .name = "example",
        .target = target,
        .version = version,
        .optimize = optimize,
        .root_source_file = b.path(EXAMPLE_DIR ++ "main.zig"),
    });
    example.root_module.addImport("quickphf", quickphf_mod);

    const example_run = b.addRunArtifact(example);

    const example_test = b.addTest(.{
        .target = target,
        .root_source_file = b.path(EXAMPLE_DIR ++ "test.zig"),
    });
    example_test.root_module.addImport("quickphf", quickphf_mod);
    example_test.step.dependOn(&example_run.step);

    const example_test_run = b.addRunArtifact(example_test);
    example_step.dependOn(&example_test_run.step);
    b.default_step.dependOn(example_step);

    // Formatting checks
    const fmt_step = b.step("fmt", "Run formatting checks");

    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
            EXAMPLE_DIR,
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    b.default_step.dependOn(fmt_step);
}

const EXAMPLE_DIR = "example/";
