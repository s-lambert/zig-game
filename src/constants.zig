const jok = @import("jok");
const sdl = jok.sdl;

pub const tile_size = 16;
pub const tile_size_f = 16.0;
pub const tiles_width = 10;
pub const tiles_height = 8;
const tiles_mulitipler = 4.0;
pub const window_height = 16 * tiles_height * tiles_mulitipler;
pub const window_width = 16 * tiles_width * tiles_mulitipler;

pub const tiles_scale: sdl.PointF = .{ .x = tiles_mulitipler, .y = tiles_mulitipler };
pub fn tile_pos(x: usize, y: usize) sdl.PointF {
    return .{
        .x = 0.0 + @as(f32, @floatFromInt(x)) * tile_size_f * tiles_mulitipler,
        .y = 0.0 + @as(f32, @floatFromInt(y)) * tile_size_f * tiles_mulitipler,
    };
}
