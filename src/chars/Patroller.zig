const std = @import("std");
const constants = @import("./constants.zig");
const rl = @import("raylib");
const sprite = @import("chars/sprite.zig");

var spritesheet_texture: rl.Texture2D = undefined;
var current_keyframe = sprite.Frame(4, 1).init(0, 0);
const anchor: rl.Vector2 = rl.Vector2.init(0, 0);
var current_pos: rl.Rectangle = .{
    .x = 2 * constants.tile_size,
    .y = 2 * constants.tile_size,
    .width = 16.0,
    .height = 16.0,
};

const EnemyType = enum {
    daoist,
    orc,
};

pub fn preload(enemyType: EnemyType) void {
    const png_data = @embedFile(switch (enemyType) {
        .daoist => "daoist.png",
        .orc => "orc.png",
    });

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
}
