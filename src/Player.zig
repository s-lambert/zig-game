const std = @import("std");
const constants = @import("./constants.zig");
const rl = @import("raylib");
const sprite = @import("chars/sprite.zig");

var spritesheet_texture: rl.Texture2D = undefined;
var current_keyframe = sprite.Frame(5, 3, 16, 24).init(1, 0);
var current_pos: rl.Rectangle = .{ .x = 0, .y = 0, .width = 16.0, .height = 24.0 };
const anchor: rl.Vector2 = rl.Vector2.init(0, 8);
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

const Image = struct {
    width: u32,
    height: u32,
};

fn getPngSize(comptime png_data: []const u8) Image {
    if (png_data.len < 24 or !std.mem.eql(u8, png_data[0..8], "\x89PNG\r\n\x1a\n")) {
        @compileError("Invalid PNG file");
    }

    const width = std.mem.readInt(u32, png_data[16..20], .big);
    const height = std.mem.readInt(u32, png_data[20..24], .big);

    return Image{ .width = width, .height = height };
}

pub fn preload() void {
    const png_data = @embedFile("player.png");
    // comptime {
    //     const size = getPngSize(png_data);
    //     @compileLog("Image size: ", size.width, "x", size.height);
    // }

    const raw_image: rl.Image = rl.loadImageFromMemory(".png", png_data);
    spritesheet_texture = rl.loadTextureFromImage(raw_image);
}

pub fn rl_draw() void {
    spritesheet_texture.drawPro(
        current_keyframe.as_rect(),
        current_pos,
        anchor,
        0.0,
        rl.Color.white,
    );

    rl.drawText("Press up/down/left/right to move character around", 0, 0, 8, rl.Color.black);
}

var key_cooldown: f32 = 0.5;
fn reset_key_cooldown() void {
    key_cooldown = 0.5;
}
pub fn rl_update() void {
    if (key_cooldown > 0.0) {
        key_cooldown -= rl.getFrameTime();
        return;
    }

    if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
        current_pos.y -= constants.tile_size;
        current_keyframe.set(3, 2);
        current_keyframe.flipped = false;
        reset_key_cooldown();
        // animation = "player_up";
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
        current_pos.y += constants.tile_size;
        current_keyframe.set(2, 0);
        current_keyframe.flipped = false;
        reset_key_cooldown();
        // animation = "player_down";
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
        current_pos.x += constants.tile_size;
        current_keyframe.set(1, 1);
        current_keyframe.flipped = true;
        reset_key_cooldown();
        // animation = "player_left_right";
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
        current_pos.x -= constants.tile_size;
        current_keyframe.set(1, 1);
        current_keyframe.flipped = false;
        reset_key_cooldown();
        // animation = "player_left_right";
        // force_replay = true;
    }
    // if (force_replay and try animator.isOver(animation)) {
    //     try animator.reset(animation);
    // }
    // if (force_replay) {
    //     animator.update(ctx.deltaSeconds());
    // }
}
