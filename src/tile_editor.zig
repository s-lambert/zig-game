const rl = @import("raylib");

fn guiRect(rect: rl.Rectangle, borderWidth: i32, borderColor: rl.Color, color: rl.Color) void {
    const x: i32 = @intFromFloat(rect.x);
    const y: i32 = @intFromFloat(rect.y);
    const width: i32 = @intFromFloat(rect.width);
    const height: i32 = @intFromFloat(rect.height);

    rl.drawRectangle(x, y, width, height, color);
    if (borderWidth > 0) {
        rl.drawRectangle(x, y, width, borderWidth, borderColor);
        rl.drawRectangle(x, y + borderWidth, borderWidth, height - (2 * borderWidth), borderColor);
        rl.drawRectangle(x + width - borderWidth, y + borderWidth, borderWidth, height - (2 * borderWidth), borderColor);
        rl.drawRectangle(x, y + height - borderWidth, width, borderWidth, borderColor);
    }
}

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 450;

    rl.initWindow(screen_width, screen_height, "Editor");
    defer rl.closeWindow();

    const tilemap_image = rl.loadImage("assets/images/dungeon_tilemap.png");
    const tilemap_texture = rl.loadTextureFromImage(tilemap_image);

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

        tilemap_texture.draw(0, 0, rl.Color.white);
        guiRect(rl.Rectangle{
            .x = 10,
            .y = 10,
            .width = 50,
            .height = 50,
        }, 2, rl.Color.light_gray, rl.Color.ray_white);
        rl.drawText("Congrats! You created your first window!", 0, 0, 20, rl.Color.black);
    }
}
