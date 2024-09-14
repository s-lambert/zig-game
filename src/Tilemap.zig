const std = @import("std");
const constants = @import("./constants.zig");
const rl = @import("raylib");

const tilemap_columns = 12;
const tilemap_rows = 11;

const first_layer = [constants.tiles_height * constants.tiles_width]u8{
    0, 0, 0, 1,  2,  2,  2,  2,  3,  0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 25, 14, 14, 26, 26, 27, 0,
    0, 0, 0, 0,  0,  0,  0,  0,  0,  0,
};

const second_layer = [constants.tiles_height * constants.tiles_width]u8{
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 86, 92, 0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
};

var tilemap_texture: rl.Texture2D = undefined;

pub fn preload() void {
    tilemap_texture = rl.loadTexture("assets/images/dungeon_tilemap.png");
}

pub fn rl_draw() void {
    draw_layer(&first_layer, false);
    draw_layer(&second_layer, true);
}

fn draw_layer(layer: []const u8, ignore_base: bool) void {
    const bounds_min_x: usize = 0;
    const bounds_max_x: usize = constants.tiles_width;
    const bounds_min_y: usize = 0;
    const bounds_max_y: usize = constants.tiles_height;

    for (layer, 0..) |tile, tile_index| {
        if (ignore_base and tile == 0) continue;

        const tile_x = tile_index % constants.tiles_width;
        const tile_y = tile_index / constants.tiles_width;

        if (!constants.xy_intersect(bounds_min_x, bounds_max_x, bounds_min_y, bounds_max_y, tile_x, tile_x, tile_y, tile_y)) {
            continue;
        }

        const spritesheet_x = tile % tilemap_columns;
        const spritesheet_y = tile / tilemap_columns;

        const tile_pos = constants.rl_tile_pos(tile_x, tile_y);

        tilemap_texture.drawRec(
            .{
                .x = @as(f32, @floatFromInt(spritesheet_x)) * constants.tile_size_f,
                .y = @as(f32, @floatFromInt(spritesheet_y)) * constants.tile_size_f,
                .width = constants.tile_size_f,
                .height = constants.tile_size_f,
            },
            tile_pos,
            rl.Color.white,
        );
    }
}
