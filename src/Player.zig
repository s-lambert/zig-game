const std = @import("std");
const constants = @import("./constants.zig");
const rl = @import("raylib");

var spritesheet_texture: rl.Texture2D = undefined;
// Don't need to flip using a boolean, can just use a negative width on current_frame
// var flip_h = false;
const current_frame: rl.Rectangle = .{ .x = 0, .y = 0, .width = 16.0, .height = 24.0 };
var current_pos: rl.Rectangle = .{ .x = 0, .y = 0, .width = 16.0, .height = 24.0 };
const anchor: rl.Vector2 = rl.Vector2.init(0, 0);
const velocity = constants.tile_size * 10;

// pub fn init(ctx: jok.Context) !void {
//     sheet = try j2d.SpriteSheet.fromPicturesInDir(
//         ctx,
//         "assets/images",
//         2000,
//         2000,
//         1,
//         true,
//         .{},
//     );
//     animator = try j2d.AnimationSystem.create(ctx.allocator());
//     const player = sheet.getSpriteByName("player").?;
//     try animator.add(
//         "player_left_right",
//         &[_]j2d.Sprite{
//             player.getSubSprite(16 * 2, 24 * 1, 16, 24),
//             player.getSubSprite(16 * 1, 24 * 1, 16, 24),
//             player.getSubSprite(16 * 3, 24 * 1, 16, 24),
//             player.getSubSprite(16 * 1, 24 * 1, 16, 24),
//         },
//         6,
//         false,
//     );
//     try animator.add(
//         "player_down",
//         &[_]j2d.Sprite{
//             player.getSubSprite(16 * 2, 24 * 0, 16, 24),
//             player.getSubSprite(16 * 1, 24 * 0, 16, 24),
//             player.getSubSprite(16 * 3, 24 * 0, 16, 24),
//             player.getSubSprite(16 * 1, 24 * 0, 16, 24),
//         },
//         6,
//         false,
//     );
//     try animator.add(
//         "player_up",
//         &[_]j2d.Sprite{
//             player.getSubSprite(16 * 2, 24 * 2, 16, 24),
//             player.getSubSprite(16 * 1, 24 * 2, 16, 24),
//             player.getSubSprite(16 * 3, 24 * 2, 16, 24),
//             player.getSubSprite(16 * 1, 24 * 2, 16, 24),
//         },
//         6,
//         false,
//     );
// }

pub fn preload() void {
    spritesheet_texture = rl.loadTexture("assets/images/player.png");
}

pub fn rl_draw() void {
    spritesheet_texture.drawPro(
        current_frame,
        current_pos,
        anchor,
        0.0,
        rl.Color.white,
    );

    rl.drawText("Press up/down/left/right to move character around", 0, 0, 20, rl.Color.black);
}

pub fn rl_update() void {
    // var force_replay = false;
    if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
        current_pos.y -= velocity * rl.getFrameTime();
        // animation = "player_up";
        // flip_h = false;
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
        current_pos.y += velocity * rl.getFrameTime();
        // animation = "player_down";
        // flip_h = false;
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
        current_pos.x += velocity * rl.getFrameTime();
        // animation = "player_left_right";
        // flip_h = true;
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
        current_pos.x -= velocity * rl.getFrameTime();
        // animation = "player_left_right";
        // flip_h = false;
        // force_replay = true;
    }
    // if (force_replay and try animator.isOver(animation)) {
    //     try animator.reset(animation);
    // }
    // if (force_replay) {
    //     animator.update(ctx.deltaSeconds());
    // }
}
