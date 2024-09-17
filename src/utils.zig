const rl = @import("raylib");

pub fn load_texture(comptime image_path: []const u8) rl.Texture2D {
    const png_data = @embedFile(image_path);
    const raw_image: rl.Image = rl.loadImageFromMemory(".png", png_data);
    return rl.loadTextureFromImage(raw_image);
}
