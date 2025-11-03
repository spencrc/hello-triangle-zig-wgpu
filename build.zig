const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zglfw_dep = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });
    const wgpu_native_dep = b.dependency("wgpu_native_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const glfw_wgpu_mod = b.addModule("glfw_wgpu", .{
        .root_source_file = b.path("src/glfw_wgpu.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "glfw", .module = zglfw_dep.module("glfw") },
            .{ .name = "wgpu", .module = wgpu_native_dep.module("wgpu") },
        },
    });
    if (builtin.os.tag == .macos) {
        glfw_wgpu_mod.addCSourceFile(.{
            .file = b.path("lib/metal/metal_layer.m"),
            .language = .objective_c,
        });
        glfw_wgpu_mod.linkFramework("QuartzCore", .{});
        glfw_wgpu_mod.linkFramework("Metal", .{});
    }

    const exe = b.addExecutable(.{
        .name = "Hello_Triangle",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/triangle.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "glfw", .module = zglfw_dep.module("glfw") },
                .{ .name = "wgpu", .module = wgpu_native_dep.module("wgpu") },
                .{ .name = "glfw_wgpu", .module = glfw_wgpu_mod },
            },
        }),
    });

    const glfw_zig_dep = b.dependency("glfw_zig", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.linkLibrary(glfw_zig_dep.artifact("glfw"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
