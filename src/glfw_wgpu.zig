const glfw = @import("glfw");
const wgpu = @import("wgpu");

const target_os = @import("builtin").target.os.tag;

pub fn createSurface(instance: *wgpu.Instance, window: *glfw.Window) !*wgpu.Surface {
    switch (target_os) {
        .linux => {
            return switch (glfw.getPlatform()) {
                .x11 => createX11Surface(instance, window),
                .wayland => createWaylandSurface(instance, window),
                else => return error.PlatformUnsupported,
            };
        },
        .macos => return createMetalSurface(instance, window),
        .windows => return createWindowsSurface(instance, window),
        else => return error.PlatformUnsupported,
    }
}

fn createX11Surface(instance: *wgpu.Instance, window: *glfw.Window) !*wgpu.Surface {
    const x11_display = glfw.getX11Display() orelse return error.SurfaceCreationError;
    const x11_window = glfw.getX11Window(window);

    const x11_surface_desc = wgpu.surfaceDescriptorFromXlibWindow(.{
        .display = x11_display,
        .window = x11_window,
    });

    return instance.createSurface(&x11_surface_desc).?;
}

fn createWaylandSurface(instance: *wgpu.Instance, window: *glfw.Window) !*wgpu.Surface {
    const wl_display = glfw.getWaylandDisplay() orelse return error.SurfaceCreationError;
    const wl_window = glfw.getWaylandWindow(window) orelse return error.SurfaceCreationError;

    const wl_surface_desc = wgpu.surfaceDescriptorFromWaylandSurface(.{
        .display = wl_display,
        .surface = wl_window,
    });

    return instance.createSurface(&wl_surface_desc).?;
}

extern fn setupMetalLayer(ns_window: *anyopaque) ?*anyopaque;
fn createMetalSurface(instance: *wgpu.Instance, window: *glfw.Window) !*wgpu.Surface {
    const ns_window = glfw.getCocoaWindow(window) orelse return error.SurfaceCreationError;
    const metal_layer = setupMetalLayer(ns_window) orelse return error.SurfaceCreationError;

    const metal_surface_desc = wgpu.surfaceDescriptorFromMetalLayer(
        .{ .layer = metal_layer },
    );

    return instance.createSurface(&metal_surface_desc).?;
}

const LPCSTR = ?[*:0]const u8;
const HMODULE = *anyopaque;
extern fn GetModuleHandleA(lpModuleName: LPCSTR) ?HMODULE;
fn createWindowsSurface(instance: *wgpu.Instance, window: *glfw.Window) !*wgpu.Surface {
    const hwnd = glfw.getWin32Window(window) orelse return error.SurfaceCreationError;
    const hmodule = GetModuleHandleA(null) orelse return error.SurfaceCreationError;

    const windows_surface_desc = wgpu.surfaceDescriptorFromWindowsHWND(.{
        .hwnd = hwnd,
        .hinstance = hmodule,
    });

    return instance.createSurface(&windows_surface_desc).?;
}
