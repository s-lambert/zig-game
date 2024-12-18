const std = @import("std");

pub const Circle = struct {
    x: f32,
    y: f32,
    radius: f32,
};

pub fn circle_collision(a: *Circle, b: *Circle) bool {
    const dist_x = a.x - b.x;
    const dist_y = a.y - b.y;
    const distance = @sqrt(std.math.pow(f32, dist_x, 2) + std.math.pow(f32, dist_y, 2));
    return distance <= (a.radius + b.radius);
}
