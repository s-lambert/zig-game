const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const Hitbox = @import("./shmup/Hitbox.zig");
const Circle = Hitbox.Circle;
const circle_collision = Hitbox.circle_collision;
const draw_hitbox = Hitbox.draw_hitbox;
const Enemy = @import("./shmup//Enemy.zig");
const Bullet = @import("./shmup/Bullet.zig");

const SHOW_HITBOXES = true;
const MAX_BULLETS = std.math.pow(usize, 4, 2);
const MAX_ENEMIES = std.math.pow(usize, 4, 2);
const MAX_ENEMY_BULLETS = std.math.pow(usize, 8, 2);

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
    next_bullet: usize,
    enemy_bullets: [MAX_ENEMY_BULLETS]Bullet,
};

var shmup_state: ShmupState = undefined;
var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var rand_impl = std.rand.DefaultPrng.init(42);

var bullet_spritesheet: rl.Texture2D = undefined;
var ships_spritesheet: rl.Texture2D = undefined;
var background_spritesheet: rl.Texture2D = undefined;

pub fn preload() void {
    bullet_spritesheet = utils.load_texture("./assets/bullets.png");
    ships_spritesheet = utils.load_texture("./assets/ships_packed.png");
    background_spritesheet = utils.load_texture("./assets/1st map.png");

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
        .next_bullet = 0,
        .enemy_bullets = std.mem.zeroes([MAX_ENEMY_BULLETS]Bullet),
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
        bullet.*.area.x = player.position.x;
        bullet.*.initial_x = player.position.x;
        bullet.*.area.y = player.position.y - player.position.radius;
        bullet.*.area.radius = 4.0;
        bullet.*.kind = if (player.next_bullet < 8) Bullet.BulletKind.Straight else Bullet.BulletKind.Wave;

        player.*.next_bullet += 1;
        player.*.next_bullet &= MAX_BULLETS - 1;
    }

    for (&player.bullets) |*bullet| {
        if (bullet.is_alive) {
            bullet.*.time_alive += delta;
            bullet.area.y -= delta * 100.0;
            if (bullet.kind == Bullet.BulletKind.Wave) {
                bullet.area.x = bullet.initial_x + 20.0 * @sin(bullet.time_alive * 5.0);
            }
            if (bullet.area.y <= 0.0) {
                bullet.is_alive = false;
            }
        }
    }

    for (&shmup_state.enemy_bullets) |*enemy_bullet| {
        if (enemy_bullet.is_alive) {
            enemy_bullet.*.time_alive += delta;
            enemy_bullet.area.y += delta * 100.0;
            if (enemy_bullet.kind == Bullet.BulletKind.Wave) {
                enemy_bullet.area.x = enemy_bullet.initial_x + 20.0 * @sin(enemy_bullet.time_alive * 5.0);
            }
            if (enemy_bullet.area.y <= 0.0) {
                enemy_bullet.is_alive = false;
            }

            if (circle_collision(&player.position, &enemy_bullet.area)) {
                enemy_bullet.is_alive = false;
                std.debug.print("Player hit.", .{});
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
            const should_shoot = enemy.update_func(enemy, delta);
            if (should_shoot) {
                fire_enemy_bullet(enemy);
            }

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

fn fire_enemy_bullet(enemy: *Enemy) void {
    const bullet = &shmup_state.enemy_bullets[shmup_state.next_bullet];
    std.debug.assert(!bullet.is_alive);

    bullet.*.is_alive = true;
    bullet.*.time_alive = 0.0;
    bullet.*.area.x = enemy.*.area.x;
    bullet.*.initial_x = bullet.*.area.x;
    bullet.*.area.y = enemy.*.area.y - enemy.*.area.radius;
    bullet.*.area.radius = 4.0;
    bullet.*.kind = Bullet.BulletKind.Straight;

    shmup_state.next_bullet += 1;
    shmup_state.next_bullet &= MAX_ENEMY_BULLETS - 1;
}

pub fn draw() void {
    rl.drawTexturePro(
        background_spritesheet,
        .{ .x = 0.0, .y = 0.0, .width = 16.0 * 16.0, .height = 16.0 * 20.0 },
        .{ .x = 0.0, .y = 0.0, .width = 16.0 * 16.0, .height = 16.0 * 20.0 },
        .{ .x = 0.0, .y = 0.0 },
        0.0,
        rl.Color.white,
    );

    const player = &shmup_state.player;
    if (SHOW_HITBOXES) {
        draw_hitbox(&player.position, rl.Color.sky_blue);
    }
    ships_spritesheet.drawPro(
        .{ .x = 0.0, .y = 0.0, .width = 32.0, .height = 32.0 },
        .{ .x = player.position.x, .y = player.position.y, .width = 16.0, .height = 16.0 },
        .{ .x = 8.0, .y = 8.0 },
        0.0,
        rl.Color.white,
    );

    for (player.bullets) |bullet| {
        if (bullet.is_alive) {
            if (SHOW_HITBOXES) {
                draw_hitbox(&bullet.area, rl.Color.green);
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
            if (SHOW_HITBOXES) {
                draw_hitbox(&enemy.area, rl.Color.yellow);
            }
            ships_spritesheet.drawPro(
                .{ .x = 0.0, .y = 128.0, .width = 32.0, .height = 32.0 },
                .{ .x = enemy.area.x, .y = enemy.area.y, .width = 32.0, .height = 32.0 },
                .{ .x = 16.0, .y = 16.0 },
                180.0,
                rl.Color.white,
            );
        }
    }

    for (shmup_state.enemy_bullets) |enemy_bullet| {
        if (enemy_bullet.is_alive) {
            if (SHOW_HITBOXES) {
                draw_hitbox(&enemy_bullet.area, rl.Color.red);
            }
            bullet_spritesheet.drawPro(
                .{ .x = 0.0, .y = 0.0, .width = 16.0, .height = 16.0 },
                .{ .x = enemy_bullet.area.x, .y = enemy_bullet.area.y, .width = 16.0, .height = 16.0 },
                .{ .x = 8.0, .y = 8.0 },
                0.0,
                rl.Color.white,
            );
        }
    }
}
