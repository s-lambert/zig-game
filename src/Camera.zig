const constants = @import("./constants.zig");
const sdl = @import("jok").sdl;

const bounds: sdl.RectangleF = .{
    .x = 0.0,
    .y = 0.0,
    .width = constants.window_width,
    .height = constants.window_height,
};

const Self = @This();
