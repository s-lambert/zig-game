const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const Hitbox = @import("./shmup/Hitbox.zig");
const Circle = Hitbox.Circle;
const circle_collision = Hitbox.circle_collision;
const Enemy = @import("./shmup//Enemy.zig");

const BulletKind = enum {
    Straight,
    Wave,
};

const Bullet = struct {
    is_alive: bool,
    time_alive: f32,
    initial_x: f32,
    area: Circle,
    kind: BulletKind,
};

const SHOW_HITBOXES = false;
const MAX_BULLETS = std.math.pow(usize, 4, 2);
const MAX_ENEMIES = std.math.pow(usize, 4, 2);

const ShmupState = struct {
    player: struct {
        position: Circle,
        next_bullet: usize,
        bullets: [MAX_BULLETS]Bullet,
        fire_cooldown: f32,
    },
    spawn_cooldown: f32,
    next_enemy: usize,
    enemies: [MAX_ENEMIES]Enemy,
};

var shmup_state: ShmupState = undefined;
var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var rand_impl = std.rand.DefaultPrng.init(42);

var player_spritesheet: rl.Texture2D = undefined;
var bullet_spritesheet: rl.Texture2D = undefined;

pub fn preload() void {
    player_spritesheet = utils.load_texture("./assets/bee.png");
    bullet_spritesheet = utils.load_texture("./assets/bullets.png");
    shmup_state = .{
        .player = .{
            .position = Circle{ .x = 120.0, .y = 120.0, .radius = 8.0 },
            .next_bullet = 0,
            .bullets = std.mem.zeroes([MAX_BULLETS]Bullet),
            .fire_cooldown = 0.0,
        },
        .spawn_cooldown = 0.0,
        .next_enemy = 0,
        .enemies = std.mem.zeroes([MAX_ENEMIES]Enemy),
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
        std.debug.assert(!bullet.is_alive);

        bullet.*.is_alive = true;
        bullet.*.time_alive = 0.0;
        bullet.*.area.x = player.*.position.x;
        bullet.*.initial_x = bullet.*.area.x;
        bullet.*.area.y = player.*.position.y - player.*.position.radius;
        bullet.*.area.radius = 4.0;
        bullet.*.kind = if (player.next_bullet < 8) BulletKind.Straight else BulletKind.Wave;

        player.*.next_bullet += 1;
        player.*.next_bullet &= MAX_BULLETS - 1;
    }

    for (&player.bullets) |*bullet| {
        if (bullet.is_alive) {
            bullet.*.time_alive += delta;
            bullet.area.y -= delta * 100.0;
            if (bullet.kind == BulletKind.Wave) {
                bullet.area.x = bullet.initial_x + 20.0 * @sin(bullet.time_alive * 5.0);
            }
            if (bullet.area.y <= 0.0) {
                bullet.is_alive = false;
            }
        }
    }

    if (shmup_state.spawn_cooldown > 0.0) {
        shmup_state.spawn_cooldown -= delta;
    } else {
        shmup_state.spawn_cooldown = 2.0;

        const enemy = &shmup_state.enemies[shmup_state.next_enemy];
        std.debug.assert(!enemy.is_alive);
        enemy.*.is_alive = true;

        enemy.*.area.x = rand_impl.random().float(f32) * 240.0;
        enemy.*.area.y = 0.0;
        enemy.*.area.radius = 10.0;
        enemy.*.kind = Enemy.EnemyKind.Shooting;
        enemy.*.update_func = Enemy.EnemyUpdateFunctions[@intFromEnum(enemy.kind)];

        shmup_state.next_enemy += 1;
        shmup_state.next_enemy &= MAX_ENEMIES - 1;
    }

    for (&shmup_state.enemies) |*enemy| {
        if (enemy.is_alive) {
            enemy.update_func(enemy, delta);

            for (&player.bullets) |*bullet| {
                if (bullet.is_alive) {
                    if (circle_collision(&enemy.area, &bullet.area)) {
                        bullet.is_alive = false;
                        enemy.is_alive = false;
                    }
                }
            }
        }
    }
}

pub fn draw() void {
    const player = &shmup_state.player;
    if (SHOW_HITBOXES) {
        rl.drawCircle(
            @intFromFloat(player.position.x),
            @intFromFloat(player.position.y),
            player.position.radius,
            rl.Color.sky_blue,
        );
    }
    player_spritesheet.drawPro(
        .{ .x = 0.0, .y = 0.0, .width = 16.0, .height = 16.0 },
        .{ .x = player.position.x, .y = player.position.y, .width = 16.0, .height = 16.0 },
        .{ .x = 8.0, .y = 8.0 },
        0.0,
        rl.Color.white,
    );

    for (player.bullets) |bullet| {
        if (bullet.is_alive) {
            if (SHOW_HITBOXES) {
                rl.drawCircle(
                    @intFromFloat(bullet.area.x),
                    @intFromFloat(bullet.area.y),
                    bullet.area.radius,
                    rl.Color.green,
                );
            }
            bullet_spritesheet.drawPro(
                .{ .x = 0.0, .y = 0.0, .width = 16.0, .height = 16.0 },
                .{ .x = bullet.area.x, .y = bullet.area.y, .width = 16.0, .height = 16.0 },
                .{ .x = 8.0, .y = 8.0 },
                0.0,
                rl.Color.white,
            );
        }
    }

    for (shmup_state.enemies) |enemy| {
        if (enemy.is_alive) {
            rl.drawCircle(
                @intFromFloat(enemy.area.x),
                @intFromFloat(enemy.area.y),
                enemy.area.radius,
                rl.Color.red,
            );
        }
    }
}
