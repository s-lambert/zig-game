const std = @import("std");
const rl = @import("raylib");

pub const tile_size = 16;
pub const tile_size_f = 16.0;
pub const tiles_width = 10;
pub const tiles_height = 8;
pub const window_height = 64 * tiles_height;
pub const window_width = 48 * tiles_width;

pub fn tile_pos(x: usize, y: usize) rl.Vector2 {
    return .{
        .x = 0.0 + @as(f32, @floatFromInt(x)) * tile_size_f,
        .y = 0.0 + @as(f32, @floatFromInt(y)) * tile_size_f,
    };
}

pub fn aabb_intersect(rect_a: *const rl.Rectangle, rect_b: *const rl.Rectangle) bool {
    const a_x_min = rect_a.x;
    const a_x_max = rect_a.x + rect_a.width;
    const a_y_min = rect_a.y;
    const a_y_max = rect_a.y + rect_a.height;
    const b_x_min = rect_b.x;
    const b_x_max = rect_b.x + rect_b.width;
    const b_y_min = rect_b.y;
    const b_y_max = rect_b.y + rect_b.height;
    return (a_x_min < b_x_max and a_x_max > b_x_min) and (a_y_min < b_y_max and a_y_max > b_y_min);
}

pub fn xy_intersect(
    x1_min: usize,
    x1_max: usize,
    y1_min: usize,
    y1_max: usize,
    x2_min: usize,
    x2_max: usize,
    y2_min: usize,
    y2_max: usize,
) bool {
    return (x1_min <= x2_max and x1_max >= x2_min) and (y1_min <= y2_max and y1_max >= y2_min);
}
