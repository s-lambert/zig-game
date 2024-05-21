const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;
const Player = @import("./Player.zig");
const Tilemap = @import("./Tilemap.zig");
const constants = @import("./constants.zig");

pub const jok_window_borderless = true;
pub const jok_window_size: jok.config.WindowSize = .{
    .custom = .{ .width = constants.window_width, .height = constants.window_height },
};

pub fn init(ctx: jok.Context) !void {
    try Tilemap.init(ctx);
    try Player.init(ctx);
}

pub fn event(ctx: jok.Context, evt: sdl.Event) !void {
    try Player.event(ctx, evt);
}

pub fn update(ctx: jok.Context) !void {
    try Player.update(ctx);
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(sdl.Color.rgb(77, 77, 77));

    j2d.begin(.{});
    defer j2d.end();

    try Tilemap.draw(ctx);
    try Player.draw(ctx);
}

pub fn quit(ctx: jok.Context) void {
    Tilemap.quit(ctx);
    Player.quit(ctx);
}
