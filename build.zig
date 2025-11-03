const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const win32_dep = b.dependency("win32", .{});
    const win32_mod = win32_dep.module("win32");

    {
        const launcher = b.addExecutable(.{
            .name = "launcher",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/launcher.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "win32", .module = win32_mod },
                },
            }),
        });
        // launcher.linkSystemLibrary("kernel32");
        // launcher.linkLibC();
        const install = b.addInstallArtifact(launcher, .{});
        b.getInstallStep().dependOn(&install.step);
    }

    // // Build the framework DLL
    // const framework = b.addSharedLibrary(.{
    //     .name = "framework",
    //     .root_source_file = b.path("framework.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // framework.linkSystemLibrary("kernel32");
    // framework.linkLibC();

    // b.installArtifact(framework);

    // // Create a run step for the launcher
    // const run_cmd = b.addRunArtifact(launcher);
    // run_cmd.step.dependOn(b.getInstallStep());

    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // const run_step = b.step("run", "Run the launcher");
    // run_step.dependOn(&run_cmd.step);
}
