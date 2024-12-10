const std = @import("std");
const rl = @import("raylib");

const Circle = struct {
    const Self = @This();

    x: f32,
    y: f32,
    radius: f32,
};

const Bullets = std.ArrayList(Circle);

const ShmupState = struct {
    player: struct {
        position: Circle,
        bullets: Bullets,
        fire_cooldown: f32,
    },
};

var shmup_state: ShmupState = undefined;

pub fn preload() void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    shmup_state = .{
        .player = .{
            .position = Circle{ .x = 120.0, .y = 120.0, .radius = 8.0 },
            .bullets = Bullets.init(arena_allocator.allocator()),
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
    }
    if (player.*.fire_cooldown <= 0.0 and rl.isKeyDown(rl.KeyboardKey.key_space)) {
        player.*.fire_cooldown = 0.2;
        try player.*.bullets.append(.{
            .x = player.*.position.x,
            .y = player.*.position.y - player.*.position.radius,
            .radius = 4.0,
        });
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

    for (player.bullets.items) |bullet| {
        rl.drawCircle(
            @intFromFloat(bullet.x),
            @intFromFloat(bullet.y),
            bullet.radius,
            rl.Color.green,
        );
    }
}
