const rl = @import("raylib");
const rg = @import("raygui");
const utils = @import("./utils.zig");
const Editor = @import("./Editor.zig");

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 450;

    rl.initWindow(screen_width, screen_height, "Editor");
    defer rl.closeWindow();

    // const tilemap_texture = utils.load_texture("./assets/dungeon_tilemap.png");

    const editor_camera: rl.Camera2D = .{
        .offset = rl.Vector2.init(0.0, 0.0),
        .target = rl.Vector2.init(0.0, 0.0),
        .rotation = 0.0,
        .zoom = 2.0,
    };

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        editor_camera.begin();
        defer editor_camera.end();

        Editor.update();
        Editor.draw();

        // tilemap_texture.draw(0, 0, rl.Color.white);
        // _ = rg.guiTextBox(rl.Rectangle{
        //     .x = 10,
        //     .y = 10,
        //     .width = 50,
        //     .height = 50,
        // }, @constCast("Test"), 8, false);
        // rl.drawText("Congrats! You created your first window!", 0, 0, 20, rl.Color.black);
    }
}
