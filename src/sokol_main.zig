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

const Vertex = struct {
    pos: [2]f32, // x, y position
    uv: [2]f32, // texture coordinates
    tex_idx: u32,
};

const Spritesheet = enum {
    TILE,
    PLAYER,
};

const Sprite = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    uv_x: f32,
    uv_y: f32,
    uv_width: f32,
    uv_height: f32,
    spritesheet: Spritesheet,
};

const MAX_SPRITES = 1000;

const state = struct {
    var pass_action: sg.PassAction = .{};
    var pip: sg.Pipeline = .{};
    var bind: sg.Bindings = .{};
    var vs_params: shd.VsParams = undefined;
    var stbi_img: zstbi.Image = undefined;
    var stbi_img_2: zstbi.Image = undefined;
    var img: sg.Image = .{};
    var img_2: sg.Image = .{};
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

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .size = @sizeOf(Vertex) * MAX_SPRITES * 4,
        .usage = .DYNAMIC,
    });

    var indices = std.mem.zeroes([MAX_SPRITES * 6]u16);

    for (0..MAX_SPRITES) |n| {
        const index_index = n * 6;
        const vertex_index = n * 4;
        // Set the vertex indices for each quad.
        // 0, 1, 2
        // 1, 3, 2
        indices[index_index + 0] = @as(u16, @intCast(vertex_index)) + 0;
        indices[index_index + 1] = @as(u16, @intCast(vertex_index)) + 1;
        indices[index_index + 2] = @as(u16, @intCast(vertex_index)) + 2;
        indices[index_index + 3] = @as(u16, @intCast(vertex_index)) + 1;
        indices[index_index + 4] = @as(u16, @intCast(vertex_index)) + 3;
        indices[index_index + 5] = @as(u16, @intCast(vertex_index)) + 2;
    }

    state.bind.index_buffer = sg.makeBuffer(.{
        .data = sg.asRange(&indices),
        .type = .INDEXBUFFER,
    });

    zstbi.init(arena_allocator.allocator());

    state.stbi_img = zstbi.Image.loadFromFile("src/assets/1st map.png", 4) catch unreachable;
    var tile_image: [6][16]sg.Range = std.mem.zeroes([6][16]sg.Range);
    tile_image[0][0] = sg.asRange(state.stbi_img.data);
    state.img = sg.makeImage(
        .{
            .width = @intCast(state.stbi_img.width),
            .height = @intCast(state.stbi_img.height),
            .data = .{
                .subimage = tile_image,
            },
        },
    );

    state.stbi_img_2 = zstbi.Image.loadFromFile("src/assets/daoist.png", 4) catch unreachable;
    var player_image: [6][16]sg.Range = std.mem.zeroes([6][16]sg.Range);
    player_image[0][0] = sg.asRange(state.stbi_img_2.data);
    state.img_2 = sg.makeImage(
        .{
            .width = @intCast(state.stbi_img_2.width),
            .height = @intCast(state.stbi_img_2.height),
            .data = .{ .subimage = player_image },
        },
    );

    state.bind.images[0] = state.img;
    state.bind.images[1] = state.img_2;
    state.bind.samplers[0] = sg.makeSampler(.{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    var pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.blankShaderDesc(sg.queryBackend())),
        .cull_mode = .NONE,
        .index_type = .UINT16,
        .depth = .{
            .write_enabled = false,
            .compare = .ALWAYS,
        },
    };
    const blend_state: sg.BlendState = .{
        .enabled = true,
        .src_factor_rgb = .SRC_ALPHA,
        .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
        .op_rgb = .ADD,
        .src_factor_alpha = .ONE,
        .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
        .op_alpha = .ADD,
    };
    pip_desc.colors[0] = .{ .blend = blend_state };

    pip_desc.layout.buffers[0].stride = @sizeOf(Vertex);
    pip_desc.layout.attrs[shd.ATTR_blank_position] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(Vertex, "pos"),
    };
    pip_desc.layout.attrs[shd.ATTR_blank_texcoord] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(Vertex, "uv"),
    };
    pip_desc.layout.attrs[shd.ATTR_blank_texture_index] = .{
        .format = .UBYTE4,
        .offset = @offsetOf(Vertex, "tex_idx"),
    };

    state.pip = sg.makePipeline(pip_desc);
}

export fn frame() void {
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);

    state.vs_params.screen_size = .{
        800.0, // screen width
        600.0, // screen height
    };
    sg.applyUniforms(0, sg.asRange(&state.vs_params));

    const single_sprite: Sprite = .{
        .x = 0.0,
        .y = 0.0,
        .width = 16.0,
        .height = 16.0,
        .uv_x = 0.0,
        .uv_y = 0.0,
        .uv_width = 16.0 / 256.0,
        .uv_height = 16.0 / 320.0,
        .spritesheet = .TILE,
    };

    const another_sprite: Sprite = .{
        .x = 16.0,
        .y = 16.0,
        .width = 16.0,
        .height = 16.0,
        .uv_x = 16.0 / 256.0,
        .uv_y = 176.0 / 320.0,
        .uv_width = 16.0 / 256.0,
        .uv_height = 16.0 / 320.0,
        .spritesheet = .TILE,
    };

    const player_sprite: Sprite = .{
        .x = 16.0,
        .y = 16.0,
        .width = 16.0,
        .height = 16.0,
        .uv_x = 16.0 / 80.0,
        .uv_y = 0.0,
        .uv_width = 16.0 / 80.0,
        .uv_height = 16.0 / 16.0,
        .spritesheet = .PLAYER,
    };

    var vertex_data: [MAX_SPRITES * 4]Vertex = std.mem.zeroes([MAX_SPRITES * 4]Vertex);
    var vertex_count: usize = 0;

    for ([_]Sprite{ single_sprite, another_sprite, player_sprite }) |sprite| {
        const x = sprite.x;
        const y = sprite.y;
        const w = sprite.width;
        const h = sprite.height;
        const u = sprite.uv_x;
        const v = sprite.uv_y;
        const uw = sprite.uv_width;
        const vh = sprite.uv_height;
        const tex_idx = @intFromEnum(sprite.spritesheet);

        vertex_data[vertex_count + 0] = .{ .pos = .{ x, y + h }, .uv = .{ u, v + vh }, .tex_idx = tex_idx };
        vertex_data[vertex_count + 1] = .{ .pos = .{ x + w, y + h }, .uv = .{ u + uw, v + vh }, .tex_idx = tex_idx };
        vertex_data[vertex_count + 2] = .{ .pos = .{ x, y }, .uv = .{ u, v }, .tex_idx = tex_idx };
        vertex_data[vertex_count + 3] = .{ .pos = .{ x + w, y }, .uv = .{ u + uw, v }, .tex_idx = tex_idx };

        vertex_count += 4;
    }

    sg.updateBuffer(state.bind.vertex_buffers[0], sg.asRange(vertex_data[0..vertex_count]));

    sg.draw(0, @intCast(3 * 6), 1);
    sg.endPass();
    sg.commit();
}

export fn input(event: ?*const sapp.Event) void {
    _ = event;
}

export fn cleanup() void {
    sg.shutdown();
    state.stbi_img.deinit();
    state.stbi_img_2.deinit();
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
