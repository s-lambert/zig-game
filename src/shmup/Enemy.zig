const Circle = @import("Hitbox.zig").Circle;

pub const EnemyKind = enum { Shooting };
const EnemyUpdateFn = *allowzero const fn (*Enemy, f32) bool;

is_alive: bool,
time_alive: f32,
area: Circle,
kind: EnemyKind,
update_func: EnemyUpdateFn,
state: usize,
fire_cooldown: f32,

const Enemy = @This();

fn entering_enemy_update(enemy: *Enemy, delta: f32) bool {
    if (enemy.is_alive) {
        if (enemy.area.y <= 120.0) {
            enemy.area.y += delta * 20.0;
        } else {
            if (enemy.fire_cooldown > 0.0) {
                enemy.fire_cooldown -= delta;
            } else {
                enemy.fire_cooldown = 2.0;
                return true;
            }
        }
    }

    return false;
}

pub const EnemyUpdateFunctions = [_]EnemyUpdateFn{
    entering_enemy_update,
};
