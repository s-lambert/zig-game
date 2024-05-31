const std = @import("std");
const constants = @import("./constants.zig");
const rl = @import("raylib");

const tilemap_columns = 12;
const tilemap_rows = 11;

const map = [constants.tiles_height * constants.tiles_width]u8{
    1, 1, 1, 1,  1,  1,  1, 1, 1, 1,
    0, 1, 5, 0,  0,  1,  5, 0, 1, 5,
    1, 1, 1, 1,  1,  1,  1, 1, 1, 1,
    8, 1, 5, 0,  0,  1,  5, 0, 1, 5,
    8, 1, 1, 1,  1,  1,  1, 1, 1, 1,
    8, 1, 5, 1,  2,  3,  5, 0, 1, 5,
    0, 1, 5, 13, 14, 15, 5, 0, 1, 5,
    0, 1, 5, 25, 26, 27, 5, 0, 1, 5,
};

var tilemap_texture: rl.Texture2D = undefined;

pub fn preload() void {
    tilemap_texture = rl.loadTexture("assets/images/dungeon_tilemap.png");
}

pub fn rl_draw() void {
    const bounds_min_x: usize = 1;
    const bounds_max_x: usize = 4;
    const bounds_min_y: usize = 1;
    const bounds_max_y: usize = 3;

    for (map, 0..) |tile, tile_index| {
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
