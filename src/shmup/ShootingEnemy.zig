const Enemy = @import("./Enemy.zig");

const States = enum {
    Entering,
    Shooting,
    Leaving,
};

pub fn update_shooting_enemy(enemy: *Enemy, delta: f32) void {
    if (!enemy.is_alive) return;

    const current_state: States = @enumFromInt(enemy.state);

    switch (current_state) {
        .Entering => {
            if (enemy.area.y <= 120.0) {
                enemy.area.y += delta * 20.0;
            } else {
                enemy.time_alive = 0.0;
                enemy.state = @intFromEnum(States.Shooting);
            }
        },
        .Shooting => {},
        .Leaving => {},
    }
}
