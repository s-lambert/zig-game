const constants = @import("./constants.zig");
const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;
const layers = [_]u8{[_]u8{ 1, 2, 3, 4 }};

pub fn init(ctx: jok.Context) !void {
    // const size = ctx.getCanvasSize();
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "assets/images",
        2000,
        2000,
        1,
        true,
        .{},
    );
}

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

const bounds: sdl.RectangleF = .{ .x = 64.0, .y = 64.0, .width = 128.0, .height = 128.0 };

pub fn draw(_: jok.Context) !void {
    const dungeon_tilemap = sheet.getSpriteByName("dungeon_tilemap").?;
    for (map, 0..) |tile, tile_index| {
        const tile_x = tile_index % constants.tiles_width;
        const tile_y = tile_index / constants.tiles_width;

        const spritesheet_x = tile % tilemap_columns;
        const spritesheet_y = tile / tilemap_columns;

        const tile_pos = constants.tile_pos(tile_x, tile_y);
        const tile_rect: sdl.RectangleF = .{ .x = tile_pos.x, .y = tile_pos.y, .width = 64.0, .height = 64.0 };

        if (!constants.aabb_intersect(&bounds, &tile_rect)) {
            continue;
        }

        try j2d.sprite(
            dungeon_tilemap.getSubSprite(
                @as(f32, @floatFromInt(spritesheet_x)) * constants.tile_size_f,
                @as(f32, @floatFromInt(spritesheet_y)) * constants.tile_size_f,
                constants.tile_size_f,
                constants.tile_size_f,
            ),
            .{
                .pos = tile_pos,
                .scale = constants.tiles_scale,
            },
        );
    }
}

pub fn quit(_: jok.Context) void {
    sheet.destroy();
}
