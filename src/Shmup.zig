const std = @import("std");
const rl = @import("raylib");

const Circle = struct {
    x: f32,
    y: f32,
    radius: f32,
};

const Bullet = struct {
    is_alive: bool,
    time_alive: f32,
    initial_x: f32,
    area: Circle,
};

const MAX_BULLETS = std.math.pow(usize, 4, 2);

const ShmupState = struct {
    player: struct {
        position: Circle,
        next_bullet: usize,
        bullets: [MAX_BULLETS]Bullet,
        fire_cooldown: f32,
    },
};

var shmup_state: ShmupState = undefined;
var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);

pub fn preload() void {
    shmup_state = .{
        .player = .{
            .position = Circle{ .x = 120.0, .y = 120.0, .radius = 8.0 },
            .next_bullet = 0,
            .bullets = std.mem.zeroes([MAX_BULLETS]Bullet),
            .fire_cooldown = 0.0,
        },
    };
}

pub fn update() !void {
    const delta = rl.getFrameTime();

    var dx: f32 = 0.0;
    dx += @floatFromInt(@intFromBool(rl.isKeyDown(rl.KeyboardKey.key_right)));
    dx -= @floatFromInt(@intFromBool(rl.isKeyDown(rl.KeyboardKey.key_left)));
    var dy: f32 = 0.0;
    dy += @floatFromInt(@intFromBool(rl.isKeyDown(rl.KeyboardKey.key_down)));
    dy -= @floatFromInt(@intFromBool(rl.isKeyDown(rl.KeyboardKey.key_up)));

    const player = &shmup_state.player;
    if (dx != 0.0 or dy != 0.0) {
        player.*.position.x += dx * delta * 100.0;
        player.*.position.y += dy * delta * 100.0;
    }

    if (player.*.fire_cooldown > 0.0) {
        player.*.fire_cooldown -= delta;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_space)) {
        player.*.fire_cooldown = 0.2;
        const bullet = &player.bullets[player.next_bullet];
        bullet.*.is_alive = true;
        bullet.*.time_alive = 0.0;
        bullet.*.area.x = player.*.position.x;
        bullet.*.initial_x = bullet.*.area.x;
        bullet.*.area.y = player.*.position.y - player.*.position.radius;
        bullet.*.area.radius = 4.0;
        player.*.next_bullet += 1;
        player.*.next_bullet &= MAX_BULLETS - 1;
    }

    for (&player.bullets) |*bullet| {
        if (bullet.is_alive) {
            bullet.*.time_alive += delta;
            bullet.area.y -= delta * 100.0;
            bullet.area.x = bullet.initial_x + 20.0 * @sin(bullet.time_alive * 5.0);
            if (bullet.area.y <= 0.0) {
                bullet.is_alive = false;
            }
        }
    }
}

pub fn draw() void {
    const player = &shmup_state.player;
    rl.drawCircle(
        @intFromFloat(player.position.x),
        @intFromFloat(player.position.y),
        player.position.radius,
        rl.Color.sky_blue,
    );

    for (player.bullets) |bullet| {
        if (bullet.is_alive) {
            rl.drawCircle(
                @intFromFloat(bullet.area.x),
                @intFromFloat(bullet.area.y),
                bullet.area.radius,
                rl.Color.green,
            );
        }
    }
}
