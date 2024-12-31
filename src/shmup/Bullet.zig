const Hitbox = @import("./Hitbox.zig");
const Circle = Hitbox.Circle;

pub const BulletKind = enum {
    Straight,
    Wave,
};

const Bullet = @This();

is_alive: bool,
time_alive: f32,
initial_x: f32,
area: Circle,
kind: BulletKind,

pub fn init_bullet(bullet: *Bullet, from: *Circle) void {
    bullet.*.is_alive = true;
    bullet.*.time_alive = 0.0;
    bullet.*.area.x = from.x;
    bullet.*.initial_x = from.x;
}
