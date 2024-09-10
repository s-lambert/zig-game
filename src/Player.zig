const std = @import("std");
const constants = @import("./constants.zig");
const rl = @import("raylib");

var spritesheet_texture: rl.Texture2D = undefined;
var current_keyframe = Frame(5, 3).init(1, 0);
var current_pos: rl.Rectangle = .{ .x = 0, .y = 0, .width = 16.0, .height = 24.0 };
const anchor: rl.Vector2 = rl.Vector2.init(0, 0);
const velocity = constants.tile_size * 10;

// fn Animation(comptime frames: [_]Frame, fps: f32) type {
//     return struct {
//         const Self = @This();

//         current: Frame = frames[0],

//         pub fn init() Self {
//             return .{};
//         }
//     };
// }

fn Frame(comptime width: u32, comptime height: u32) type {
    return struct {
        const Self = @This();

        x: u32,
        y: u32,
        flipped: bool = false, // Flipping is just setting width to negative

        pub fn init(x: u32, y: u32) Self {
            if (x >= width) @compileError("X coordinate out of bounds");
            if (y >= height) @compileError("Y coordinate out of bounds");
            return Self{ .x = x, .y = y };
        }

        pub fn set(self: *Self, comptime x: u32, comptime y: u32) void {
            if (x >= width) @compileError("X coordinate out of bounds");
            if (y >= height) @compileError("Y coordinate out of bounds");
            self.x = x;
            self.y = y;
        }

        pub fn as_rect(self: *Self) rl.Rectangle {
            return .{
                .x = @floatFromInt(self.x * 16),
                .y = @floatFromInt(self.y * 24),
                .width = if (self.flipped) -16.0 else 16.0,
                .height = 24.0,
            };
        }
    };
}

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

    const raw_timig: rl.Image = rl.loadImageFromMemory(".png", png_data);
    spritesheet_texture = rl.loadTextureFromImage(raw_timig);
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

pub fn rl_update() void {
    // var force_replay = false;
    if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
        current_pos.y -= velocity * rl.getFrameTime();
        current_keyframe.set(3, 2);

        // animation = "player_up";
        // flip_h = false;
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
        current_pos.y += velocity * rl.getFrameTime();
        current_keyframe.set(2, 0);
        // animation = "player_down";
        // flip_h = false;
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
        current_pos.x += velocity * rl.getFrameTime();
        current_keyframe.set(1, 1);
        // animation = "player_left_right";
        // flip_h = true;
        // force_replay = true;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
        current_pos.x -= velocity * rl.getFrameTime();
        current_keyframe.set(1, 1);
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
