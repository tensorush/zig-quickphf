const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = std.Build.LazyPath.relative("src/lib.zig");
    const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

    // Dependencies
    const quickdiv_dep = b.dependency("quickdiv", .{
        .target = target,
        .optimize = optimize,
    });
    const quickdiv_mod = quickdiv_dep.module("quickdiv");

    // Module
    const quickphf_mod = b.addModule("quickphf", .{ .root_source_file = root_source_file });
    quickphf_mod.addImport("quickdiv", quickdiv_mod);

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "quickphf",
        .target = target,
        .version = version,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });
    lib.root_module.addImport("quickdiv", quickdiv_mod);

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Docs
    const docs_step = b.step("docs", "Emit docs");

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
    b.default_step.dependOn(docs_step);

    // Example
    const example_step = b.step("example", "Run example");

    const example = b.addExecutable(.{
        .name = "example",
        .target = target,
        .version = version,
        .optimize = optimize,
        .root_source_file = std.Build.LazyPath.relative("example/main.zig"),
    });
    example.root_module.addImport("quickphf", quickphf_mod);

    const example_run = b.addRunArtifact(example);
    example_step.dependOn(&example_run.step);

    // Example test
    const example_test_step = b.step("example_test", "Run example test");

    const example_test = b.addTest(.{
        .target = target,
        .root_source_file = std.Build.LazyPath.relative("example/test.zig"),
    });
    example_test.root_module.addImport("quickphf", quickphf_mod);

    const example_test_run = b.addRunArtifact(example_test);
    example_test_run.step.dependOn(example_step);
    example_test_step.dependOn(&example_test_run.step);
    b.default_step.dependOn(example_test_step);

    // Coverage
    const cov_step = b.step("cov", "Generate coverage");

    const cov_run = b.addSystemCommand(&.{ "kcov", "--clean", "--include-pattern=src/", "kcov-output" });
    cov_run.addArtifactArg(example_test);
    cov_step.dependOn(&cov_run.step);
    b.default_step.dependOn(cov_step);

    // Lints
    const lints_step = b.step("lints", "Run lints");

    const lints = b.addFmt(.{
        .paths = &.{ "src/", "build.zig" },
        .check = true,
    });
    lints_step.dependOn(&lints.step);
    b.default_step.dependOn(lints_step);
}
