const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;

pub fn init(ctx: jok.Context) !void {
    const size = ctx.getCanvasSize();
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "assets/images",
        @intFromFloat(size.x),
        @intFromFloat(size.y),
        1,
        true,
        .{},
    );
}

pub fn draw(_: jok.Context) !void {
    const dungeon_tilemap = sheet.getSpriteByName("dungeon_tilemap").?;
    try j2d.sprite(
        dungeon_tilemap.getSubSprite(32, 16, 16, 16),
        .{
            .pos = sdl.PointF{ .x = 200, .y = 200 },
            .depth = 0.1,
        },
    );
}

pub fn quit(_: jok.Context) void {
    sheet.destroy();
}
