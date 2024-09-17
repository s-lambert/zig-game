const rl = @import("raylib");
const constants = @import("./constants.zig");
const sprite = @import("./sprite.zig");
const Game = @import("./Game.zig");

const game_camera: rl.Camera2D = .{
    .offset = rl.Vector2.init(0.0, 0.0),
    .target = rl.Vector2.init(0.0, 0.0),
    .rotation = 0.0,
    .zoom = 2.0,
};

pub fn main() !void {
    rl.initWindow(constants.window_width, constants.window_height, "Game");
    defer rl.closeWindow();

    Game.preload();

    while (!rl.windowShouldClose()) {
        Game.update();
        draw();
    }
}

fn draw() void {
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(rl.Color.ray_white);
    game_camera.begin();
    defer game_camera.end();

    Game.draw();
}
