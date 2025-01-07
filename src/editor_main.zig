const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("./utils.zig");
const Editor = @import("./Editor.zig");
const constants = @import("./constants.zig");

const editor_camera: rl.Camera2D = .{
    .offset = rl.Vector2.init(0.0, 0.0),
    .target = rl.Vector2.init(0.0, 0.0),
    .rotation = 0.0,
    .zoom = 2.0,
};

pub fn main() !void {
    rl.initWindow(constants.window_width, constants.window_height + 32, "Editor");
    defer rl.closeWindow();

    Editor.preload();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        editor_camera.begin();
        defer editor_camera.end();

        Editor.update();
        Editor.draw();
    }
}
