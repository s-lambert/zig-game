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

const sprite_size = 16.0;
const render_scale = 4.0;

const Position = struct { x: i32 = 0, y: i32 = 0 };

const GameState = struct {
    player_position: Position,
    timing: struct {
        tick: u32 = 0,
        tick_accum: i32 = 0,
    } = .{},
    input: struct {
        up: bool = false,
        down: bool = false,
        left: bool = false,
        right: bool = false,
    } = .{},
};
var game_state: GameState = .{
    .player_position = .{ .x = 13, .y = 9 },
};

const DrawState = struct {
    sprites: [MAX_SPRITES]Sprite = std.mem.zeroes([MAX_SPRITES]Sprite),
    next_sprite: usize = 0,
    num_sprites: usize = 0,

    fn draw_tile(self: *@This(), world_pos: *const Position, frame_pos: *const Position, tex: Texture) void {
        std.debug.assert(self.next_sprite < MAX_SPRITES);

        var spritesheet_width: f32 = undefined;
        var spritesheet_height: f32 = undefined;
        switch (tex) {
            .PLAYER => {
                spritesheet_width = 80.0;
                spritesheet_height = 16.0;
            },
            .TILE => {
                spritesheet_width = 256.0;
                spritesheet_height = 320.0;
            },
        }

        self.sprites[self.next_sprite] = .{
            .world_rect = .{
                .x = @as(f32, @floatFromInt(world_pos.x)) * sprite_size,
                .y = @as(f32, @floatFromInt(world_pos.y)) * sprite_size,
                .width = sprite_size,
                .height = sprite_size,
            },
            .spritesheet_rect = .{
                .x = (@as(f32, @floatFromInt(frame_pos.x)) * sprite_size) / spritesheet_width,
                .y = (@as(f32, @floatFromInt(frame_pos.y)) * sprite_size) / spritesheet_height,
                .width = sprite_size / spritesheet_width,
                .height = sprite_size / spritesheet_height,
            },
            .spritesheet_texture = tex,
        };

        self.next_sprite += 1;
        self.num_sprites += 1;
        std.debug.assert(self.num_sprites <= MAX_SPRITES);
    }

    fn reset(self: *@This()) void {
        self.next_sprite = 0;
        self.num_sprites = 0;
    }
};
var draw_state: DrawState = .{};

const Rect = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

const QuadVertex = struct {
    pos: [2]f32, // x, y position
    uv: [2]f32, // texture coordinates
    tex_idx: u32,
};

const Texture = enum {
    TILE,
    PLAYER,
};

const Sprite = struct {
    world_rect: Rect,
    spritesheet_rect: Rect,
    spritesheet_texture: Texture,
};

const MAX_SPRITES = 10000;

const render_state = struct {
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

    render_state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0, .g = 0, .a = 1 },
    };

    render_state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .size = @sizeOf(QuadVertex) * MAX_SPRITES * 4,
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

    render_state.bind.index_buffer = sg.makeBuffer(.{
        .data = sg.asRange(&indices),
        .type = .INDEXBUFFER,
    });

    zstbi.init(arena_allocator.allocator());

    render_state.stbi_img = zstbi.Image.loadFromFile("src/assets/1st map.png", 4) catch unreachable;
    var tile_image: [6][16]sg.Range = std.mem.zeroes([6][16]sg.Range);
    tile_image[0][0] = sg.asRange(render_state.stbi_img.data);
    render_state.img = sg.makeImage(
        .{
            .width = @intCast(render_state.stbi_img.width),
            .height = @intCast(render_state.stbi_img.height),
            .data = .{
                .subimage = tile_image,
            },
        },
    );

    render_state.stbi_img_2 = zstbi.Image.loadFromFile("src/assets/daoist.png", 4) catch unreachable;
    var player_image: [6][16]sg.Range = std.mem.zeroes([6][16]sg.Range);
    player_image[0][0] = sg.asRange(render_state.stbi_img_2.data);
    render_state.img_2 = sg.makeImage(
        .{
            .width = @intCast(render_state.stbi_img_2.width),
            .height = @intCast(render_state.stbi_img_2.height),
            .data = .{ .subimage = player_image },
        },
    );

    render_state.bind.images[0] = render_state.img;
    render_state.bind.images[1] = render_state.img_2;
    render_state.bind.samplers[0] = sg.makeSampler(.{
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

    pip_desc.layout.buffers[0].stride = @sizeOf(QuadVertex);
    pip_desc.layout.attrs[shd.ATTR_blank_position] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(QuadVertex, "pos"),
    };
    pip_desc.layout.attrs[shd.ATTR_blank_texcoord] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(QuadVertex, "uv"),
    };
    pip_desc.layout.attrs[shd.ATTR_blank_texture_index] = .{
        .format = .UBYTE4,
        .offset = @offsetOf(QuadVertex, "tex_idx"),
    };

    render_state.pip = sg.makePipeline(pip_desc);
}

const MAX_FRAME_TIME_NS = 33_333_333.0;
const TICK_TOLERANCE_NS = 1_000_000;
const TICK_DURATION_NS = 16_666_666;

export fn frame() void {
    var frame_time_ns = @as(f32, @floatCast(sapp.frameDuration() * 1000000000.0));
    if (frame_time_ns > MAX_FRAME_TIME_NS) {
        frame_time_ns = MAX_FRAME_TIME_NS;
    }

    game_state.timing.tick_accum += @as(i32, @intFromFloat(frame_time_ns));
    while (game_state.timing.tick_accum > -TICK_TOLERANCE_NS) {
        game_state.timing.tick_accum -= TICK_DURATION_NS;
        game_state.timing.tick += 1;

        // Move player
        var move_to: Position = .{};
        if (game_state.input.up) move_to.y -= 1;
        if (game_state.input.down) move_to.y += 1;
        if (game_state.input.left) move_to.x -= 1;
        if (game_state.input.right) move_to.x += 1;

        game_state.player_position.x += move_to.x;
        game_state.player_position.y += move_to.y;

        game_state.player_position.x = std.math.clamp(game_state.player_position.x, 0, 13);
        game_state.player_position.y = std.math.clamp(game_state.player_position.y, 0, 9);
    }

    draw_state.reset();

    const tile_a_pos: Position = .{ .x = 0, .y = 0 };
    const tile_a_frame: Position = .{ .x = 0, .y = 0 };
    draw_state.draw_tile(&tile_a_pos, &tile_a_frame, .TILE);

    const tile_b_pos: Position = .{ .x = 13, .y = 9 };
    const tile_b_frame: Position = .{ .x = 1, .y = 11 };
    draw_state.draw_tile(&tile_b_pos, &tile_b_frame, .TILE);

    const player_frame: Position = .{ .x = 1, .y = 0 };
    draw_state.draw_tile(&game_state.player_position, &player_frame, .PLAYER);

    render();
}

fn render() void {
    sg.beginPass(.{ .action = render_state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(render_state.pip);
    sg.applyBindings(render_state.bind);

    render_state.vs_params.screen_size = .{
        @floatFromInt(sapp.width()), // screen width
        @floatFromInt(sapp.height()), // screen height
    };
    sg.applyUniforms(0, sg.asRange(&render_state.vs_params));

    var vertex_data: [MAX_SPRITES * 4]QuadVertex = std.mem.zeroes([MAX_SPRITES * 4]QuadVertex);
    var vertex_count: usize = 0;

    const scale = 4.0;
    for (draw_state.sprites) |sprite| {
        const x = sprite.world_rect.x * scale;
        const y = sprite.world_rect.y * scale;
        const w = sprite.world_rect.width * scale;
        const h = sprite.world_rect.height * scale;

        const u = sprite.spritesheet_rect.x;
        const v = sprite.spritesheet_rect.y;
        const uw = sprite.spritesheet_rect.width;
        const vh = sprite.spritesheet_rect.height;
        const tex_idx = @intFromEnum(sprite.spritesheet_texture);

        // Bottom-left
        vertex_data[vertex_count + 0] = .{
            .pos = .{ x, y + h },
            .uv = .{ u, v + vh },
            .tex_idx = tex_idx,
        };
        // Bottom-right
        vertex_data[vertex_count + 1] = .{
            .pos = .{ x + w, y + h },
            .uv = .{ u + uw, v + vh },
            .tex_idx = tex_idx,
        };
        // Top-left
        vertex_data[vertex_count + 2] = .{
            .pos = .{ x, y },
            .uv = .{ u, v },
            .tex_idx = tex_idx,
        };
        // Top-right
        vertex_data[vertex_count + 3] = .{
            .pos = .{ x + w, y },
            .uv = .{ u + uw, v },
            .tex_idx = tex_idx,
        };

        vertex_count += 4;
    }

    sg.updateBuffer(render_state.bind.vertex_buffers[0], sg.asRange(vertex_data[0..vertex_count]));

    // Draw 6 vertexes for each sprite, 6 vertexes is 1 quad
    sg.draw(0, @intCast(draw_state.num_sprites * 6), 1);
    sg.endPass();
    sg.commit();
}

export fn input(ev: ?*const sapp.Event) void {
    if (ev) |event| {
        if (event.type == .KEY_DOWN) {
            switch (event.key_code) {
                .ESCAPE => sapp.quit(),

                .UP, .W => game_state.input.up = true,
                .DOWN, .S => game_state.input.down = true,
                .LEFT, .A => game_state.input.left = true,
                .RIGHT, .D => game_state.input.right = true,
                else => {},
            }
        }
        if (event.type == .KEY_UP) {
            switch (event.key_code) {
                .UP, .W => game_state.input.up = false,
                .DOWN, .S => game_state.input.down = false,
                .LEFT, .A => game_state.input.left = false,
                .RIGHT, .D => game_state.input.right = false,
                else => {},
            }
        }
    }
}

export fn cleanup() void {
    sg.shutdown();
    render_state.stbi_img.deinit();
    render_state.stbi_img_2.deinit();
    zstbi.deinit();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = input,
        .cleanup_cb = cleanup,
        .width = 14 * sprite_size * render_scale,
        .height = 10 * sprite_size * render_scale,
        .sample_count = 1,
        .icon = .{ .sokol_default = true },
        .window_title = "blank.zig",
        .logger = .{ .func = slog.func },
    });
}
