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

const mat4x4 = [constants.tiles_height][constants.tiles_width]u8{
    [_]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]u8{ 0, 1, 5, 0, 0, 1, 5, 0, 1, 5 },
    [_]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]u8{ 8, 1, 5, 0, 0, 1, 5, 0, 1, 5 },
    [_]u8{ 8, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]u8{ 8, 1, 5, 0, 0, 1, 5, 0, 1, 5 },
    [_]u8{ 0, 1, 5, 0, 0, 1, 5, 0, 1, 5 },
    [_]u8{ 0, 1, 5, 0, 0, 1, 5, 0, 1, 5 },
};

pub fn draw(_: jok.Context) !void {
    const dungeon_tilemap = sheet.getSpriteByName("dungeon_tilemap").?;
    for (mat4x4, 0..) |row, rowNum| {
        for (row, 0..) |tile, colNum| {
            try j2d.sprite(
                dungeon_tilemap.getSubSprite(
                    @as(f32, @floatFromInt(tile)) * 16.0,
                    16,
                    16,
                    16,
                ),
                .{
                    .pos = constants.tile_pos(colNum, rowNum),
                },
            );
        }
    }
}

pub fn quit(_: jok.Context) void {
    sheet.destroy();
}
