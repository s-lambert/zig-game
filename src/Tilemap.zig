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

pub fn draw(_: jok.Context) !void {
    const dungeon_tilemap = sheet.getSpriteByName("dungeon_tilemap").?;
    for (map, 0..) |tile, tileNum| {
        const colNum = tileNum % constants.tiles_width;
        const rowNum = tileNum / constants.tiles_width;

        const tileColNum = tile % tilemap_columns;
        const tileRowNum = tile / tilemap_columns;

        try j2d.sprite(
            dungeon_tilemap.getSubSprite(
                @as(f32, @floatFromInt(tileColNum)) * 16.0,
                @as(f32, @floatFromInt(tileRowNum)) * 16.0,
                16,
                16,
            ),
            .{
                .pos = constants.tile_pos(colNum, rowNum),
                .scale = constants.tiles_scale,
            },
        );
    }
}

pub fn quit(_: jok.Context) void {
    sheet.destroy();
}
