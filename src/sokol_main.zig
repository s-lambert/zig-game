const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const sshape = sokol.shape;
const zstbi = @import("zstbi");
const vec3 = @import("math.zig").Vec3;
const mat4 = @import("math.zig").Mat4;
const assert = @import("std").debug.assert;
const shd = @import("shaders/blank.glsl.zig");

const state = struct {
    var pass_action: sg.PassAction = .{};
    var pip: sg.Pipeline = .{};
    var bind: sg.Bindings = .{};
    var vs_params: shd.VsParams = undefined;
    var stbi_img: zstbi.Image = undefined;
    var img: sg.Image = .{};
};

var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0, .g = 0, .a = 1 },
    };

    zstbi.init(arena_allocator.allocator());

    state.stbi_img = zstbi.Image.loadFromFile("src/assets/1st map.png", 4) catch unreachable;

    var sub_image: [6][16]sg.Range = std.mem.zeroes([6][16]sg.Range);
    sub_image[0][0] = sg.asRange(state.stbi_img.data);
    state.img = sg.makeImage(
        .{
            .width = @intCast(state.stbi_img.width),
            .height = @intCast(state.stbi_img.height),
            .data = .{
                .subimage = sub_image,
            },
        },
    );

    state.bind.images[0] = state.img;
    state.bind.samplers[1] = sg.makeSampler(.{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    const pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.blankShaderDesc(sg.queryBackend())),
        .primitive_type = .TRIANGLES,
        .cull_mode = .NONE,
    };

    state.pip = sg.makePipeline(pip_desc);
}

export fn frame() void {
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);

    state.vs_params.sprite_rect = .{
        0.0 / 256.0, // x
        0.0 / 320.0, // y
        32.0 / 256.0, // w
        32.0 / 320.0, // h
    };
    state.vs_params.screen_size = .{
        800.0, // screen width
        600.0, // screen height
    };

    sg.applyUniforms(2, sg.asRange(&state.vs_params));

    sg.draw(0, 6, 1);
    sg.endPass();
    sg.commit();
}

export fn input(event: ?*const sapp.Event) void {
    _ = event;
}

export fn cleanup() void {
    sg.shutdown();
    state.stbi_img.deinit();
    zstbi.deinit();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = input,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "blank.zig",
        .logger = .{ .func = slog.func },
    });
}
