const std = @import("std");
const glfw = @import("glfw");
const wgpu = @import("wgpu");
const glfw_webgpu = @import("glfw_wgpu");

var window: *glfw.Window = undefined;
var device: *wgpu.Device = undefined;
var queue: *wgpu.Queue = undefined;
var surface: *wgpu.Surface = undefined;
var uncaptured_error_callback_handle: wgpu.UncapturedErrorCallback = undefined;
var surface_format: wgpu.TextureFormat = undefined;
var pipeline: *wgpu.RenderPipeline = undefined;

fn init() !bool {
    try glfw.init();

    window = try glfw.createWindow(640, 480, "Hello Triangle", null, null);

    var instance = wgpu.Instance.create(null).?;
    defer instance.release();

    surface = try glfw_webgpu.createSurface(instance, window);

    const adapter_request = instance.requestAdapterSync(&wgpu.RequestAdapterOptions{
        .next_in_chain = null,
        .compatible_surface = surface,
    }, 0);
    var adapter = switch (adapter_request.status) {
        .success => adapter_request.adapter.?,
        else => return error.NoAdapter,
    };
    defer adapter.release();

    const device_desc: wgpu.DeviceDescriptor = .{
        .required_feature_count = 0,
        .required_limits = null,
    };

    const device_request = adapter.requestDeviceSync(instance, &device_desc, 0);
    device = switch (device_request.status) {
        .success => device_request.device.?,
        else => return error.NoDevice,
    };

    queue = device.getQueue().?;

    var capabilities: wgpu.SurfaceCapabilities = undefined;
    _ = surface.getCapabilities(adapter, &capabilities);
    surface_format = capabilities.formats[0];

    surface.configure(&wgpu.SurfaceConfiguration{
        .next_in_chain = null,
        .width = 640,
        .height = 480,
        .usage = wgpu.TextureUsages.render_attachment,
        .format = surface_format,
        .view_format_count = 0,
        .device = device,
        .present_mode = .fifo,
        .alpha_mode = .auto,
    });

    init_pipeline();

    return true;
}

fn init_pipeline() void {
    const shader_module = device.createShaderModule(&wgpu.shaderModuleWGSLDescriptor(.{
        .code = @embedFile("triangle.wgsl"),
    })).?;
    defer shader_module.release();

    const color_targets = &[_]wgpu.ColorTargetState{
        wgpu.ColorTargetState{
            .format = surface_format,
            .blend = &wgpu.BlendState{
                .color = wgpu.BlendComponent{
                    .operation = .add,
                    .src_factor = .src_alpha,
                    .dst_factor = .one_minus_src_alpha,
                },
                .alpha = wgpu.BlendComponent{
                    .operation = .add,
                    .src_factor = .zero,
                    .dst_factor = .one,
                },
            },
        },
    };

    pipeline = device.createRenderPipeline(&wgpu.RenderPipelineDescriptor{
        .vertex = .{
            .module = shader_module,
            .entry_point = wgpu.StringView.fromSlice("vs_main"),
        },
        .primitive = wgpu.PrimitiveState{},
        .fragment = &wgpu.FragmentState{
            .module = shader_module,
            .entry_point = wgpu.StringView.fromSlice("fs_main"),
            .target_count = color_targets.len,
            .targets = color_targets.ptr,
        },
        .multisample = wgpu.MultisampleState{},
    }).?;
}

fn main_loop() void {
    glfw.pollEvents();

    var surface_texture: wgpu.SurfaceTexture = undefined;
    var target_view = get_next_surface_texture_view(&surface_texture) orelse return;
    defer target_view.release();

    const encoder = device.createCommandEncoder(&wgpu.CommandEncoderDescriptor{}).?;
    defer encoder.release();

    const color_attachments = &[_]wgpu.ColorAttachment{
        wgpu.ColorAttachment{
            .view = target_view,
            .resolve_target = null,
            .load_op = .clear,
            .store_op = .store,
            .clear_value = wgpu.Color{ .r = 0.9, .g = 0.1, .b = 0.2, .a = 1.0 },
        },
    };

    const render_pass = encoder.beginRenderPass(&wgpu.RenderPassDescriptor{
        .color_attachment_count = color_attachments.len,
        .color_attachments = color_attachments.ptr,
    }).?;

    render_pass.setPipeline(pipeline);
    render_pass.draw(3, 1, 0, 0);
    render_pass.end();
    render_pass.release();

    const cmd = encoder.finish(&wgpu.CommandBufferDescriptor{}).?;
    defer cmd.release();

    queue.submit(&[_]*wgpu.CommandBuffer{cmd});

    _ = surface.present();

    _ = device.poll(false, &0);
}

fn get_next_surface_texture_view(surface_texture: *wgpu.SurfaceTexture) ?*wgpu.TextureView {
    surface.getCurrentTexture(surface_texture);
    if (surface_texture.status != .success_optimal) {
        return null;
    }

    const texture = surface_texture.texture.?;

    const view_desc: wgpu.TextureViewDescriptor = .{
        .format = texture.getFormat(),
        .dimension = .@"2d",
        .base_mip_level = 0,
        .mip_level_count = 1,
        .base_array_layer = 0,
        .array_layer_count = 1,
        .aspect = .all,
    };

    return texture.createView(&view_desc);
}

fn terminate() void {
    pipeline.release();
    surface.unconfigure();
    queue.release();
    surface.release();
    device.release();
    glfw.destroyWindow(window);
    glfw.terminate();
}

pub fn main() !void {
    if (!try init()) {
        return;
    }

    while (!glfw.windowShouldClose(window)) {
        main_loop();
    }

    terminate();
}
