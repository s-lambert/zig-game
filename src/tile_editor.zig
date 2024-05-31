const rl = @import("raylib");

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 450;

    rl.initWindow(screen_width, screen_height, "Editor");
    defer rl.closeWindow();

    const tilemap_image = rl.loadImage("assets/images/dungeon_tilemap.png");
    const tilemap_texture = rl.loadTextureFromImage(tilemap_image);
    // const scarfy: rl.Texture = rl.Texture.init("assets/images/scarfy.png");

    const editor_camera: rl.Camera2D = .{
        .offset = rl.Vector2.init(0.0, 0.0),
        .target = rl.Vector2.init(0.0, 0.0),
        .rotation = 0.0,
        .zoom = 4.0,
    };

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        editor_camera.begin();
        defer editor_camera.end();

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);

        tilemap_texture.draw(0, 0, rl.Color.white);
    }
}
