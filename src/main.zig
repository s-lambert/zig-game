const Player = @import("./Player.zig");
const Tilemap = @import("./Tilemap.zig");
const constants = @import("./constants.zig");
const rl = @import("raylib");

pub fn main() !void {
    rl.initWindow(constants.window_width, constants.window_height, "Game");
    defer rl.closeWindow();

    const game_camera: rl.Camera2D = .{
        .offset = rl.Vector2.init(0.0, 0.0),
        .target = rl.Vector2.init(0.0, 0.0),
        .rotation = 0.0,
        .zoom = 1.0,
    };

    Tilemap.preload();
    Player.preload();

    while (!rl.windowShouldClose()) {
        Player.rl_update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        game_camera.begin();
        defer game_camera.end();

        Tilemap.rl_draw();
        Player.rl_draw();
    }
}
