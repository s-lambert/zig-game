const std = @import("std");
const rl = @import("raylib");
const sprite = @import("./sprite.zig");
const constants = @import("./constants.zig");
const utils = @import("./utils.zig");

// spritesheet columns / rows
const tilemap_columns = 12;
const tilemap_rows = 11;

// Can only walk on 0 or 14
const first_layer = [constants.tiles_height * constants.tiles_width]u8{
    0, 0, 0, 1,  2,  2,  2,  2,  3,  0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 13, 14, 14, 14, 14, 15, 0,
    0, 0, 0, 25, 14, 14, 26, 26, 27, 0,
    0, 0, 0, 0,  0,  0,  0,  0,  0,  0,
};

const second_layer = [constants.tiles_height * constants.tiles_width]u8{
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
    0, 0, 0, 0, 86, 92, 0, 0, 0, 0,
    0, 0, 0, 0, 0,  0,  0, 0, 0, 0,
};

const GameState = struct {
    player: struct {
        spritesheet: rl.Texture2D,
        position: sprite.Position,
        keyframe: sprite.Frame(5, 3, 16, 24),
    },
    enemy: struct {
        spritesheet: rl.Texture2D,
        position: sprite.Position,
        keyframe: sprite.Frame(4, 1, 16, 16),
    },
    tilemap: struct {
        spritesheet: rl.Texture2D,
    },
};
var game_state = GameState{
    .player = .{
        .spritesheet = undefined,
        .position = sprite.Position{ .x = 0, .y = 0, .height = 24.0 },
        .keyframe = sprite.Frame(5, 3, 16, 24).init(1, 0),
    },
    .enemy = .{
        .spritesheet = undefined,
        .position = sprite.Position{ .x = 5, .y = 2, .height = 16.0 },
        .keyframe = sprite.Frame(4, 1, 16, 16).init(0, 0),
    },
    .tilemap = .{
        .spritesheet = undefined,
    },
};
const default_anchor: rl.Vector2 = rl.Vector2.init(0, 8);

pub fn preload() void {
    game_state.player.spritesheet = utils.load_texture("./assets/player.png");
    game_state.enemy.spritesheet = utils.load_texture("./assets/daoist.png");
    game_state.tilemap.spritesheet = utils.load_texture("./assets/dungeon_tilemap.png");
}

fn can_move_to(from: sprite.Position, dir_x: i32, dir_y: i32) bool {
    if ((from.x == 0 and dir_x == -1) or
        (from.y == 0 and dir_y == -1) or
        (from.x == constants.tiles_width - 1 and dir_x == 1) or
        (from.y == constants.tiles_height - 1 and dir_y == 1))
    {
        return false;
    }

    const x = @as(i32, @intCast(from.x)) + dir_x;
    const y = @as(i32, @intCast(from.y)) + dir_y;
    const tile_index = y * constants.tiles_width + x;

    const tile = first_layer[@as(usize, @intCast(tile_index))];
    return tile == 0 or tile == 14;
}

var key_cooldown: f32 = 0.5;
fn reset_key_cooldown() void {
    key_cooldown = 0.5;
}
pub fn update() void {
    if (key_cooldown > 0.0) {
        key_cooldown -= rl.getFrameTime();
        return;
    }
    const player = &game_state.player;
    if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
        if (can_move_to(player.*.position, 0, -1)) {
            player.*.position.y -= 1;
        }
        player.*.keyframe.set(3, 2);
        player.*.keyframe.flipped = false;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
        if (can_move_to(player.*.position, 0, 1)) {
            player.*.position.y += 1;
        }
        player.*.keyframe.set(2, 0);
        player.*.keyframe.flipped = false;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
        if (can_move_to(player.*.position, 1, 0)) {
            player.*.position.x += 1;
        }
        player.*.keyframe.set(1, 1);
        player.*.keyframe.flipped = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
        if (can_move_to(player.*.position, -1, 0)) {
            player.*.position.x -= 1;
        }
        player.*.keyframe.set(1, 1);
        player.*.keyframe.flipped = false;
    } else {
        return;
    }
    reset_key_cooldown();
}

fn draw_layer(layer: []const u8, ignore_base: bool) void {
    const bounds_min_x: usize = 0;
    const bounds_max_x: usize = constants.tiles_width;
    const bounds_min_y: usize = 0;
    const bounds_max_y: usize = constants.tiles_height;

    for (layer, 0..) |tile, tile_index| {
        if (ignore_base and tile == 0) continue;

        const tile_x = tile_index % constants.tiles_width;
        const tile_y = tile_index / constants.tiles_width;

        if (!constants.xy_intersect(bounds_min_x, bounds_max_x, bounds_min_y, bounds_max_y, tile_x, tile_x, tile_y, tile_y)) {
            continue;
        }

        const spritesheet_x = tile % tilemap_columns;
        const spritesheet_y = tile / tilemap_columns;

        const tile_pos = constants.rl_tile_pos(tile_x, tile_y);

        game_state.tilemap.spritesheet.drawRec(
            .{
                .x = @as(f32, @floatFromInt(spritesheet_x)) * constants.tile_size_f,
                .y = @as(f32, @floatFromInt(spritesheet_y)) * constants.tile_size_f,
                .width = constants.tile_size_f,
                .height = constants.tile_size_f,
            },
            tile_pos,
            rl.Color.white,
        );
    }
}

pub fn draw() void {
    draw_layer(&first_layer, false);
    draw_layer(&second_layer, true);

    const player = &game_state.player;
    player.*.spritesheet.drawPro(
        player.keyframe.as_rect(),
        player.position.as_rect(),
        default_anchor,
        0.0,
        rl.Color.white,
    );

    const enemy = &game_state.enemy;
    enemy.*.spritesheet.drawPro(
        enemy.keyframe.as_rect(),
        enemy.position.as_rect(),
        default_anchor,
        0.0,
        rl.Color.white,
    );

    rl.drawText("Press up/down/left/right to move character around", 0, 0, 8, rl.Color.black);
}
