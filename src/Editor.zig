const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const sprite = @import("./sprite.zig");

const EditorState = struct {
    cursor: struct {
        position: sprite.Position,
    },
};
var editor_state = EditorState{
    .cursor = .{
        .position = sprite.Position{
            .x = 0,
            .y = 0,
            .height = 16.0,
        },
    },
};

var key_cooldown: f32 = 0.125;
fn reset_key_cooldown() void {
    key_cooldown += 0.125;
}
pub fn update() void {
    if (key_cooldown > 0.0) {
        key_cooldown -= rl.getFrameTime();
        return;
    }
    const cursor = &editor_state.cursor;
    if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
        cursor.*.position.y -= 1;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
        cursor.*.position.y += 1;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
        cursor.*.position.x += 1;
    } else if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
        cursor.*.position.x -= 1;
    } else {
        return;
    }
    reset_key_cooldown();
}

var mouse_position = rl.Vector2.init(0.0, 0.0);
pub fn draw() void {
    _ = rg.guiGrid(
        .{
            .x = 0,
            .y = 0,
            .width = 800,
            .height = 450,
        },
        "",
        16.0,
        1,
        &mouse_position,
    );

    rl.drawRectangleLinesEx(
        editor_state.cursor.position.as_rect(),
        0.5,
        rl.Color.black,
    );
}
