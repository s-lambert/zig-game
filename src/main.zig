const std = @import("std");
const sokol = @import("sokol");

export fn init() void {}

export fn frame() void {}

export fn input(_: ?*const sokol.app.Event) void {}

export fn cleanup() void {}

pub fn main() !void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = input,
        .cleanup_cb = cleanup,
        .width = 500,
        .height = 500,
        .window_title = "game.zig",
        .logger = .{ .func = sokol.log.func },
    });
}
