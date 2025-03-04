const std = @import("std");

pub fn build(b: *std.Build) void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/root.zig");
    const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 1 };

    // Module
    const mod = b.addModule("quickphf", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addLibrary(.{
        .name = "quickphf",
        .version = version,
        .root_module = mod,
    });

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    install_step.dependOn(lib_step);

    // Documentation
    const docs_step = b.step("doc", "Emit documentation");
    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
    install_step.dependOn(docs_step);

    // Example
    const example_step = b.step("example", "Run example");

    const example = b.addExecutable(.{
        .name = "example",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path(EXAMPLE_DIR ++ "main.zig"),
        }),
    });
    example.root_module.addImport("quickphf", mod);

    const example_run = b.addRunArtifact(example);
    example_step.dependOn(&example_run.step);

    install_step.dependOn(example_step);

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
}

const EXAMPLE_DIR = "example/";
