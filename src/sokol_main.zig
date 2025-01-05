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
const display_shd = @import("shaders/post_process.glsl.zig");

const sprite_size = 16.0;
const render_scale = 4.0;
const tiles_width = 14;
const tiles_height = 10;
const screen_width = tiles_width * sprite_size * render_scale;
const screen_height = tiles_height * sprite_size * render_scale;
const offscreen_sample_count = 1;

const dungeon: [tiles_width * tiles_height]usize = .{
    0, 1,  2, 3,  4, 5,  6, 7, 8, 9,  10, 11, 12, 13,
    0, 12, 0, 0,  0, 0,  0, 0, 0, 0,  0,  0,  0,  0,
    0, 0,  0, 0,  0, 0,  0, 0, 0, 12, 12, 12, 0,  0,
    0, 0,  0, 12, 0, 0,  0, 0, 0, 0,  0,  0,  0,  0,
    0, 0,  0, 0,  0, 0,  0, 0, 0, 0,  0,  0,  0,  0,
    0, 0,  0, 0,  0, 0,  0, 0, 0, 0,  0,  0,  0,  0,
    0, 0,  0, 0,  0, 0,  0, 0, 0, 0,  0,  0,  0,  0,
    0, 0,  0, 0,  0, 12, 0, 0, 0, 0,  0,  0,  0,  0,
    0, 0,  0, 0,  0, 0,  0, 0, 0, 0,  0,  0,  0,  0,
    0, 0,  0, 0,  0, 0,  0, 0, 0, 0,  0,  0,  0,  0,
};

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
            .DUNGEON => {
                spritesheet_width = 192.0;
                spritesheet_height = 176.0;
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

const DisplayVertex = struct {
    pos: [2]f32,
    uv: [2]f32,
};

const QuadVertex = struct {
    pos: [2]f32, // x, y position
    uv: [2]f32, // texture coordinates
    tex_idx: u32,
};

const Texture = enum {
    TILE,
    PLAYER,
    DUNGEON,
};

const Sprite = struct {
    world_rect: Rect,
    spritesheet_rect: Rect,
    spritesheet_texture: Texture,
};

const MAX_SPRITES = 10000;

var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);

const render_state = struct {
    const offscreen = struct {
        var pass_action: sg.PassAction = .{};
        var attachments: sg.Attachments = .{};
        var pip: sg.Pipeline = .{};
        var bind: sg.Bindings = .{};
        var vs_params: shd.VsParams = undefined;
    };
    const display = struct {
        var pass_action: sg.PassAction = .{};
        var pip: sg.Pipeline = .{};
        var bind: sg.Bindings = .{};
    };
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // offscreen pass action: clear to black
    render_state.offscreen.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.25, .g = 0.25, .b = 0.25, .a = 1.0 },
    };

    var img_desc = sg.ImageDesc{
        .render_target = true,
        .width = screen_width,
        .height = screen_height,
        .pixel_format = .RGBA8,
        .sample_count = offscreen_sample_count,
    };
    const color_img = sg.makeImage(img_desc);
    img_desc.pixel_format = .DEPTH;
    const depth_img = sg.makeImage(img_desc);

    var atts_desc = sg.AttachmentsDesc{};
    atts_desc.colors[0].image = color_img;
    atts_desc.depth_stencil.image = depth_img;
    render_state.offscreen.attachments = sg.makeAttachments(atts_desc);

    render_state.offscreen.pip = sg.makePipeline(.{
        .shader = sg.makeShader(shd.blankShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .cull_mode = .NONE,
        .sample_count = offscreen_sample_count,
        .depth = .{
            .pixel_format = .DEPTH,
            .compare = .ALWAYS,
            .write_enabled = false,
        },
        .layout = init: {
            var l = sg.VertexLayoutState{};
            l.buffers[0].stride = @sizeOf(QuadVertex);
            l.attrs[shd.ATTR_blank_position] = .{ .format = .FLOAT2, .offset = @offsetOf(QuadVertex, "pos") };
            l.attrs[shd.ATTR_blank_texcoord] = .{ .format = .FLOAT2, .offset = @offsetOf(QuadVertex, "uv") };
            l.attrs[shd.ATTR_blank_texture_index] = .{ .format = .UBYTE4, .offset = @offsetOf(QuadVertex, "tex_idx") };
            break :init l;
        },
        .colors = init: {
            var c: [4]sg.ColorTargetState = .{ .{}, .{}, .{}, .{} };
            c[0].pixel_format = .RGBA8;
            c[0].blend = .{
                .enabled = true,
                .src_factor_rgb = .SRC_ALPHA,
                .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
                .op_rgb = .ADD,
                .src_factor_alpha = .ONE,
                .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
                .op_alpha = .ADD,
            };
            break :init c;
        },
    });

    render_state.offscreen.bind.vertex_buffers[0] = sg.makeBuffer(.{
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
    render_state.offscreen.bind.index_buffer = sg.makeBuffer(.{
        .data = sg.asRange(&indices),
        .type = .INDEXBUFFER,
    });

    zstbi.init(arena_allocator.allocator());
    defer zstbi.deinit();

    var tile_stbi = zstbi.Image.loadFromFile("src/assets/1st map.png", 4) catch unreachable;
    var tile_image: [6][16]sg.Range = std.mem.zeroes([6][16]sg.Range);
    tile_image[0][0] = sg.asRange(tile_stbi.data);
    defer tile_stbi.deinit();

    var player_sbti = zstbi.Image.loadFromFile("src/assets/daoist.png", 4) catch unreachable;
    var player_image: [6][16]sg.Range = std.mem.zeroes([6][16]sg.Range);
    player_image[0][0] = sg.asRange(player_sbti.data);
    defer player_sbti.deinit();

    var dungeon_stbi = zstbi.Image.loadFromFile("src/assets/dungeon_tilemap.png", 4) catch unreachable;
    var dungeon_image: [6][16]sg.Range = std.mem.zeroes([6][16]sg.Range);
    dungeon_image[0][0] = sg.asRange(dungeon_stbi.data);
    defer dungeon_stbi.deinit();

    render_state.offscreen.bind.images[0] = sg.makeImage(.{
        .width = @intCast(tile_stbi.width),
        .height = @intCast(tile_stbi.height),
        .data = .{ .subimage = tile_image },
    });
    render_state.offscreen.bind.images[1] = sg.makeImage(.{
        .width = @intCast(player_sbti.width),
        .height = @intCast(player_sbti.height),
        .data = .{ .subimage = player_image },
    });
    render_state.offscreen.bind.images[2] = sg.makeImage(.{
        .width = @intCast(dungeon_stbi.width),
        .height = @intCast(dungeon_stbi.height),
        .data = .{ .subimage = dungeon_image },
    });
    render_state.offscreen.bind.samplers[0] = sg.makeSampler(.{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    // display pass action: clear to blue-ish
    render_state.display.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.25, .g = 0.45, .b = 0.65, .a = 1.0 },
    };

    render_state.display.pip = sg.makePipeline(.{
        .shader = sg.makeShader(display_shd.postShaderDesc(sg.queryBackend())),
        .layout = init: {
            var l = sg.VertexLayoutState{};
            l.attrs[display_shd.ATTR_post_position] = .{ .format = .FLOAT2, .offset = @offsetOf(DisplayVertex, "pos") };
            l.attrs[display_shd.ATTR_post_texcoord] = .{ .format = .FLOAT2, .offset = @offsetOf(DisplayVertex, "uv") };
            break :init l;
        },
        .index_type = .UINT16,
        .cull_mode = .NONE,
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
    });

    // Display shader vertex/index buffers
    const post_vertices = [_]DisplayVertex{
        .{ .pos = .{ -1.0, -1.0 }, .uv = .{ 0.0, 1.0 } },
        .{ .pos = .{ 1.0, -1.0 }, .uv = .{ 1.0, 1.0 } },
        .{ .pos = .{ -1.0, 1.0 }, .uv = .{ 0.0, 0.0 } },
        .{ .pos = .{ 1.0, 1.0 }, .uv = .{ 1.0, 0.0 } },
    };
    const post_indices = [_]u16{ 0, 1, 2, 1, 3, 2 };
    render_state.display.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&post_vertices),
    });
    render_state.display.bind.index_buffer = sg.makeBuffer(.{
        .data = sg.asRange(&post_indices),
        .type = .INDEXBUFFER,
    });

    render_state.display.bind.images[display_shd.IMG_offscreen_texture] = color_img;
    render_state.display.bind.samplers[display_shd.SMP_offscreen_sampler] = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .REPEAT,
        .wrap_v = .REPEAT,
    });
}

const MAX_FRAME_TIME_NS = 66_666_666.0;
const TICK_TOLERANCE_NS = 1_000_000;
const TICK_DURATION_NS = 33_333_333;

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

    for (dungeon, 0..) |tile, tile_index| {
        const tile_x = tile_index % tiles_width;
        const tile_y = tile_index / tiles_width;

        const tileset_width = 12;
        const frame_x = tile % tileset_width;
        const frame_y = tile / tileset_width;

        const tile_pos: Position = .{ .x = @intCast(tile_x), .y = @intCast(tile_y) };
        const tile_frame: Position = .{ .x = @intCast(frame_x), .y = @intCast(frame_y) };
        draw_state.draw_tile(&tile_pos, &tile_frame, .DUNGEON);
    }

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
    // Offscreen pass
    sg.beginPass(.{
        .action = render_state.offscreen.pass_action,
        .attachments = render_state.offscreen.attachments,
    });
    sg.applyPipeline(render_state.offscreen.pip);
    sg.applyBindings(render_state.offscreen.bind);

    render_state.offscreen.vs_params.screen_size = .{
        @floatFromInt(sapp.width()), // screen width
        @floatFromInt(sapp.height()), // screen height
    };
    sg.applyUniforms(0, sg.asRange(&render_state.offscreen.vs_params));

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

    sg.updateBuffer(render_state.offscreen.bind.vertex_buffers[0], sg.asRange(vertex_data[0..vertex_count]));

    // Draw 6 vertexes for each sprite, 6 vertexes is 1 quad
    sg.draw(0, @intCast(draw_state.num_sprites * 6), 1);
    sg.endPass();

    // Display pass
    sg.beginPass(.{ .action = render_state.display.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(render_state.display.pip);
    sg.applyBindings(render_state.display.bind);
    // Draw 6 vertexes for 1 full-screen quad
    sg.draw(0, 6, 1);
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
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = input,
        .cleanup_cb = cleanup,
        .width = screen_width,
        .height = screen_height,
        .sample_count = 1,
        .icon = .{ .sokol_default = true },
        .window_title = "blank.zig",
        .logger = .{ .func = slog.func },
    });
}
