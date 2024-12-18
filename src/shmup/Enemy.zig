const Circle = @import("Hitbox.zig").Circle;

pub const EnemyKind = enum { Shooting };
const EnemyUpdateFn = *allowzero const fn (*Enemy, f32) void;

is_alive: bool,
time_alive: f32,
area: Circle,
kind: EnemyKind,
update_func: EnemyUpdateFn,
state: usize,

const Enemy = @This();

fn entering_enemy_update(enemy: *Enemy, delta: f32) void {
    if (enemy.is_alive) {
        if (enemy.area.y <= 120.0) {
            enemy.area.y += delta * 20.0;
        }
    }
}

pub const EnemyUpdateFunctions = [_]EnemyUpdateFn{
    entering_enemy_update,
};
