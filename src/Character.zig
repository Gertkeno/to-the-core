// animtion frames
const _1 = [6]u8{ 0xb6, 0xf3, 0x82, 0x3c, 0xbe, 0x38 };
const _2 = [6]u8{ 0xb7, 0xf2, 0x82, 0x3c, 0x3e, 0xac };
const _3 = [6]u8{ 0xb7, 0xf2, 0x80, 0x3e, 0x8e, 0xa2 };
const _4 = [6]u8{ 0xb6, 0xf3, 0x02, 0xbc, 0xbc, 0x8a };

const frames: []const [6]u8 = &.{
    _1, _2, _3, _4,
};

const Self = @This();

const Controller = @import("Controller.zig");
const w4 = @import("wasm4.zig");

x: i32,
y: i32,
animation: u8 = 0,
flipme: bool = false,

pub fn draw(self: Self) void {
    w4.DRAW_COLORS.* = 0x4023;
    const flags = w4.BLIT_2BPP | if (self.flipme) w4.BLIT_FLIP_X else 0;
    w4.blit(&frames[self.animation >> 2], self.x >> 2, self.y >> 2, 4, 6, flags);
}

pub fn update(self: *Self, controls: Controller) void {
    if (controls.held.right) {
        self.x += 1;
        self.flipme = false;
    } else if (controls.held.left) {
        self.x -= 1;
        self.flipme = true;
    }

    if (controls.held.up) {
        self.y -= 1;
    } else if (controls.held.down) {
        self.y += 1;
    }

    if (@bitCast(u8, controls.held) & 0b11110000 != 0) {
        self.animation += 1;
        if (self.animation >= (frames.len << 2)) {
            self.animation = 0;
        }
    }
}
