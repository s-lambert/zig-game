const rl = @import("raylib");

pub fn Frame(
    comptime rows: u32,
    comptime columns: u32,
    comptime column_width: i32,
    comptime row_height: i32,
) type {
    return struct {
        const Self = @This();

        row: u32,
        col: u32,
        flipped: bool = false, // Flipping is just setting width to negative

        pub fn init(row: u32, col: u32) Self {
            if (row >= rows) @compileError("X coordinate out of bounds");
            if (col >= columns) @compileError("Y coordinate out of bounds");
            return Self{ .row = row, .col = col };
        }

        pub fn set(self: *Self, comptime x: u32, comptime y: u32) void {
            if (x >= rows) @compileError("X coordinate out of bounds");
            if (y >= columns) @compileError("Y coordinate out of bounds");
            self.row = x;
            self.col = y;
        }

        pub fn as_rect(self: *Self) rl.Rectangle {
            return .{
                .x = @floatFromInt(self.row * column_width),
                .y = @floatFromInt(self.col * row_height),
                .width = if (self.flipped) -column_width else column_width,
                .height = row_height,
            };
        }
    };
}
