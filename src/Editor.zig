const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const constants = @import("./constants.zig");
const sprite = @import("./sprite.zig");
const utils = @import("./utils.zig");

const sprite_size = 16.0;
const canvas_width = 14;
const canvas_height = 10;
const tileset_width = 12;
const tileset_height = 11;

const EditorState = struct {
    selected_tile: struct {
        index: usize = 0,
    } = .{},
};
var editor_state = EditorState{};

var dungeon_spritesheet: rl.Texture2D = undefined;

pub fn preload() void {
    dungeon_spritesheet = utils.load_texture("./assets/dungeon_tilemap.png");
}

var key_cooldown: f32 = 0.125;
fn reset_key_cooldown() void {
    key_cooldown += 0.125;
}
pub fn update() void {
    if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
        const mouse_pos = rl.getMousePosition();
        if (mouse_pos.y >= 0 and mouse_pos.y < sprite_size * canvas_height * 2.0 and
            mouse_pos.x >= 0 and mouse_pos.x < sprite_size * canvas_width * 2.0)
        {
            const tile_x: i32 = @intFromFloat(mouse_pos.x / sprite_size / 2.0);
            const tile_y: i32 = @intFromFloat(mouse_pos.y / sprite_size / 2.0);
            std.debug.print("canvas clicked: {d}, {d}\n", .{ tile_x, tile_y });
        }

        if (mouse_pos.y >= sprite_size * canvas_height * 2.0 and
            mouse_pos.y < sprite_size * canvas_height * 2.0 + sprite_size * tileset_height * 2.0 and
            mouse_pos.x >= 0 and mouse_pos.x < sprite_size * tileset_width * 2.0)
        {
            const tile_x: i32 = @intFromFloat(mouse_pos.x / sprite_size / 2.0);
            const tile_y: i32 = @intFromFloat((mouse_pos.y - sprite_size * canvas_height * 2.0) / sprite_size / 2.0);
            std.debug.print("tileset clicked: {d}, {d}\n", .{ tile_x, tile_y });
        }
    }

    if (key_cooldown > 0.0) {
        key_cooldown -= rl.getFrameTime();
        return;
    }
    reset_key_cooldown();
}

// Doesn't seem to calculate correctly.
var ignore_grid_position = rl.Vector2.init(0.0, 0.0);

pub fn draw() void {
    _ = rg.guiGrid(
        .{
            .x = 0,
            .y = 0,
            .width = sprite_size * canvas_width,
            .height = sprite_size * canvas_height,
        },
        "CANVAS",
        sprite_size,
        1,
        &ignore_grid_position,
    );

    const tileset_rect = .{
        .x = 0.0,
        .y = sprite_size * canvas_height,
        .width = 192.0,
        .height = 176.0,
    };

    rl.drawTexturePro(
        dungeon_spritesheet,
        .{
            .x = 0.0,
            .y = 0.0,
            .width = 192.0,
            .height = 176.0,
        },
        tileset_rect,
        .{ .x = 0.0, .y = 0.0 },
        0.0,
        rl.Color.white,
    );

    _ = rg.guiGrid(tileset_rect, "TILESET", sprite_size, 1, &ignore_grid_position);

    // rl.drawRectangleLinesEx(
    //     editor_state.cursor.position.as_rect(),
    //     1.0,
    //     rl.Color.black,
    // );
}
