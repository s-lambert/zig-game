const constants = @import("./constants.zig");
const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;
var animator: *j2d.AnimationSystem = undefined;
var animation: []const u8 = "player_down";
var flip_h = false;
const anchor_point: sdl.PointF = .{ .x = 0.0, .y = 0.3333 };

const velocity = 100;
var pos: sdl.PointF = constants.tile_pos(0, 3);

pub fn init(ctx: jok.Context) !void {
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "assets/images",
        2000,
        2000,
        1,
        true,
        .{},
    );
    animator = try j2d.AnimationSystem.create(ctx.allocator());
    const player = sheet.getSpriteByName("player").?;
    try animator.add(
        "player_left_right",
        &[_]j2d.Sprite{
            player.getSubSprite(16 * 2, 24 * 1, 16, 24),
            player.getSubSprite(16 * 1, 24 * 1, 16, 24),
            player.getSubSprite(16 * 3, 24 * 1, 16, 24),
            player.getSubSprite(16 * 1, 24 * 1, 16, 24),
        },
        6,
        false,
    );
    try animator.add(
        "player_down",
        &[_]j2d.Sprite{
            player.getSubSprite(16 * 2, 24 * 0, 16, 24),
            player.getSubSprite(16 * 1, 24 * 0, 16, 24),
            player.getSubSprite(16 * 3, 24 * 0, 16, 24),
            player.getSubSprite(16 * 1, 24 * 0, 16, 24),
        },
        6,
        false,
    );
    try animator.add(
        "player_up",
        &[_]j2d.Sprite{
            player.getSubSprite(16 * 2, 24 * 2, 16, 24),
            player.getSubSprite(16 * 1, 24 * 2, 16, 24),
            player.getSubSprite(16 * 3, 24 * 2, 16, 24),
            player.getSubSprite(16 * 1, 24 * 2, 16, 24),
        },
        6,
        false,
    );
}

pub fn event(_: jok.Context, _: sdl.Event) !void {
    // your event processing code
}

pub fn update(ctx: jok.Context) !void {
    var force_replay = false;
    if (ctx.isKeyPressed(.up)) {
        pos.y -= velocity * ctx.deltaSeconds();
        animation = "player_up";
        flip_h = false;
        force_replay = true;
    } else if (ctx.isKeyPressed(.down)) {
        pos.y += velocity * ctx.deltaSeconds();
        animation = "player_down";
        flip_h = false;
        force_replay = true;
    } else if (ctx.isKeyPressed(.right)) {
        pos.x += velocity * ctx.deltaSeconds();
        animation = "player_left_right";
        flip_h = true;
        force_replay = true;
    } else if (ctx.isKeyPressed(.left)) {
        pos.x -= velocity * ctx.deltaSeconds();
        animation = "player_left_right";
        flip_h = false;
        force_replay = true;
    }
    if (force_replay and try animator.isOver(animation)) {
        try animator.reset(animation);
    }
    if (force_replay) {
        animator.update(ctx.deltaSeconds());
    }
}

pub fn draw(ctx: jok.Context) !void {
    try j2d.sprite(
        try animator.getCurrentFrame(animation),
        .{
            .pos = pos,
            .scale = constants.tiles_scale,
            .flip_h = flip_h,
            .anchor_point = anchor_point,
        },
    );
    jok.font.debugDraw(
        ctx,
        .{ .x = 0, .y = 0 },
        "Press up/down/left/right to move character around",
        .{},
    );
}

pub fn quit(_: jok.Context) void {
    sheet.destroy();
    animator.destroy();
}
