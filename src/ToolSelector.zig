const Character = @import("Character.zig");
const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");
const Bank = @import("Bank.zig");
const Tool = @import("Tool.zig");

const w4 = @import("wasm4.zig");

const ticky = Sound{
    .freq = .{
        .start = 900,
        .end = 700,
    },
    .adsr = .{
        .sustain = 4,
        .release = 4,
    },

    .volume = 20,
    .mode = w4.TONE_PULSE2,
};

extern const bank: Bank;

const Self = @This();
index: usize = 0,

pub fn selecting(self: *Self, char: *Character, controls: Controller) bool {
    if (self.index > 0 and controls.released.up) {
        self.index -= 1;
        ticky.play();
    } else if (self.index < Tool.array.len and controls.released.down) {
        self.index += 1;
        ticky.play();
    }

    if (controls.released.x) {
        if (self.index == Tool.array.len) {
            char.tool = null;
            char.resourcePreview = null;
        } else {
            char.tool = Tool.array[self.index];
            char.resourcePreview = &bank.stockpile.mana;
        }
        ticky.play();
        return true;
    } else {
        return false;
    }
}

const startAtY = 152 - Tool.array.len * 8;
pub fn draw(self: Self) void {
    for (Tool.array) |entry, n| {
        if (n == self.index) {
            w4.DRAW_COLORS.* = 0x14;
        } else {
            w4.DRAW_COLORS.* = 0x21;
        }

        const y = @intCast(i32, startAtY + n * 8);
        w4.blit(entry.icon, 0, y, 8, 8, w4.BLIT_1BPP);
        w4.text(entry.name, 8, y);
    }

    if (Tool.array.len == self.index) {
        w4.DRAW_COLORS.* = 0x14;
    } else {
        w4.DRAW_COLORS.* = 0x21;
    }
    w4.text("none", 8, 152);
}