# [wgpu-native Hello Triangle](https://github.com/spencrc/hello-triangle-zig-wgpu)
[![ci](https://github.com/spencrc/hello-triangle-zig-wgpu/actions/workflows/main.yml/badge.svg)](https://github.com/spencrc/hello-triangle-zig-wgpu/actions/workflows/main.yml)

Opens a window using [glfw](https://github.com/glfw/glfw) and draws a triangle with [wgpu-native](https://github.com/gfx-rs/wgpu-native/), all in [Zig](https://ziglang.org/). Builds and runs on Windows, Linux (using either X11 or Wayland), and MacOS.

This project is based on the [Hello Triangle](https://eliemichel.github.io/LearnWebGPU/basic-3d-rendering/hello-triangle.html) from the C++ [Learn WebGPU native](https://eliemichel.github.io/LearnWebGPU/) course.

## Dependencies
This project depends on:
- [spencrc/zglfw](https://github.com/spencrc/zglfw)
- [tiawl/glfw.zig](https://github.com/tiawl/glfw.zig#d4e35d81f30ec1398d5b40744968459d5a8786e6)
- [bronter/wgpu_native_zig](https://github.com/bronter/wgpu_native_zig)

If you want to build this project using [zig-gamedev/zglfw](https://github.com/zig-gamedev/zglfw), you'll have to make very minor changes to the parameters passed to each glfw function call. 
The bindings used here aim to mirror zig-gamedev/zglfw's enums and function names whilst remaining as close as possible to glfw's function definitions.

# [glfw_wgpu](https://github.com/spencrc/hello-triangle-zig-wgpu/blob/45abaf73ae617d1013f86ef34d7cbde2da9b9cf1/src/glfw_wgpu.zig)
The `glfw_wgpu.zig` file serves as an extension to glfw for use with wgpu-native. It's accompanied by `metal_layer.m` which provides the Objective-C code necessary for retrieving the Metal layer on MacOS systems. 

## Overview
`glfw_wgpu` simply provides the following function:
```zig
fn createSurface(instance: *wgpu.Instance, window: *glfw.Window) !*wgpu.Surface;
```
Given a glfw window, `createSurface` returns a wgpu surface that correlates to the window's backend.

## Usage
You can add `glfw_wgpu` as a dependency to your project by running `zig fetch` in your project,
```
zig fetch --save "git+https://github.com/spencrc/hello-triangle-zig-wgpu.git`
```
Then, you'll need to add `glfw_webgpu` as an import to your executable. It should look something like this:
```zig
const glfw_wgpu_dep = b.dependency("glfw_wgpu", .{
    .target = target,
    .optimize = optimize,
});

const exe = b.addExecutable(.{
    .name = "your_project",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "glfw_wgpu", .module = glfw_wgpu_dep.module("glfw_wgpu") },
        },
    }),
});
```

Alternatively, if you wish to use `glfw_wgpu` but don't want to rely on the same dependencies, you can simply copy `lib/` into your project's root and `glfw_wgpu.zig` into your project's `src/`. Then, include the following in your `build.zig` for MacOS support:
```zig
if (target.result.os.tag == .macos) {
    exe.root_module.addCSourceFile(.{
        .file = b.path("lib/metal/metal_layer.m"),
        .language = .objective_c,
    });
    exe.root_module.linkFramework("QuartzCore", .{});
    exe.root_module.linkFramework("Metal", .{});
}
```
## Credit
`glfw_wgpu.zig` is based on [TheOnlySilverClaw/Valdala](https://github.com/TheOnlySilverClaw/Valdala/tree/development)'s [`surface.zig`](https://github.com/TheOnlySilverClaw/Valdala/blob/b843063d9b4219e89155dd1a048013335eebccff/src/glfw-wgpu/surface.zig), whilst `metal_layer.m` is a copy of [`metal_layer.m`](https://github.com/TheOnlySilverClaw/Valdala/blob/b843063d9b4219e89155dd1a048013335eebccff/src/glfw-wgpu/metal_layer.m).
Please check out Valdala!
