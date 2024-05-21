const jok = @import("jok");
const sdl = jok.sdl;

pub const tile_size = 16;
pub const tile_size_f = 16.0;
pub const tiles_width = 10;
pub const tiles_height = 8;
pub const window_height = 16 * tiles_height;
pub const window_width = 16 * tiles_width;

pub fn tile_pos(x: usize, y: usize) sdl.PointF {
    return .{
        .x = 0.0 + @as(f32, @floatFromInt(x)) * tile_size_f,
        .y = 0.0 + @as(f32, @floatFromInt(y)) * tile_size_f,
    };
}
