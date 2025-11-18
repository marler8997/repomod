const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zin_dep = b.dependency("zin", .{});
    const zin_mod = zin_dep.module("zin");
    const win32_dep = zin_dep.builder.dependency("win32", .{});
    // const win32_dep = b.dependency("win32", .{});
    const win32_mod = win32_dep.module("win32");

    // old code that I'll probably need later in order to inject my own managed dll
    const mutiny_managed_dll = blk: {
        const compile = b.addSystemCommand(&.{
            "C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\csc.exe",
            "/target:library",
        });
        const out_dll = compile.addPrefixedOutputFileArg("/out:", "MutinyManaged.dll");
        compile.addFileArg(b.path("managed/MutinyManaged.cs"));
        break :blk out_dll;
    };
    const install_mutiny_managed_dll = b.addInstallLibFile(
        mutiny_managed_dll,
        "MutinyManaged.dll",
    );
    b.step("managed-dll", "").dependOn(&install_mutiny_managed_dll.step);

    const mutiny_native_dll = b.addLibrary(.{
        .name = "Mutiny",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/mutinydll.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "win32", .module = win32_mod },
                // .{ .name = "managed_dll", .module = b.createModule(.{
                //     .root_source_file = mutiny_managed_dll,
                // }) },
            },
        }),
    });
    const install_mutiny_native_dll = b.addInstallArtifact(mutiny_native_dll, .{});
    b.getInstallStep().dependOn(&install_mutiny_native_dll.step);

    const test_game = b.addExecutable(.{
        .name = "TestGame",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/testgame.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "win32", .module = win32_mod },
            },
        }),
    });
    const install_test_game = b.addInstallArtifact(test_game, .{});
    b.step("install-testgame", "").dependOn(&install_test_game.step);

    {
        const run = b.addRunArtifact(test_game);
        run.step.dependOn(&install_test_game.step);
        b.step("testgame-raw", "").dependOn(&run.step);
    }

    {
        const injector = b.addExecutable(.{
            .name = "injector",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/injector.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "win32", .module = win32_mod },
                },
            }),
        });
        const install = b.addInstallArtifact(injector, .{});
        b.getInstallStep().dependOn(&install.step);

        const run = b.addRunArtifact(injector);
        run.step.dependOn(&install.step);
        run.step.dependOn(&install_mutiny_native_dll.step);
        // run.step.dependOn(&install_mutiny_managed_dll.step);
        run.step.dependOn(&install_test_game.step);

        run.addArtifactArg(mutiny_native_dll);
        run.addArtifactArg(test_game);
        b.step("testgame", "").dependOn(&run.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "Mutiny",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/mutiny.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "zin", .module = zin_mod },
                },
            }),
            .win32_manifest = b.path("src/win32dpiaware.manifest"),
        });
        exe.addWin32ResourceFile(.{
            .file = b.path("src/mutiny.rc"),
        });
        const run = b.addRunArtifact(exe);
        if (b.args) |a| run.addArgs(a);
        b.step("run", "").dependOn(&run.step);
    }

    {
        const t = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/Vm.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        if (target.result.os.tag == .windows) {
            t.root_module.addImport("win32", win32_mod);
        }
        const run = b.addRunArtifact(t);
        b.step("test", "").dependOn(&run.step);
    }
}
