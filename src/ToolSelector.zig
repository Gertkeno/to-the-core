const Character = @import("Character.zig");
const Controller = @import("Controller.zig");
const Bank = @import("Bank.zig");
const Tool = @import("Tool.zig");

const w4 = @import("wasm4.zig");

extern const bank: Bank;

const Self = @This();
index: usize = 0,

pub fn selecting(self: *Self, char: *Character, controls: Controller) bool {
    if (self.index > 0 and controls.released.up) {
        self.index -= 1;
    } else if (self.index < Tool.array.len - 1 and controls.released.down) {
        self.index += 1;
    }

    if (controls.released.x) {
        char.tool = Tool.array[self.index];
        char.resourcePreview = &bank.stockpile.mana;
        return true;
    } else {
        return false;
    }
}

const startAtY = 160 - Tool.array.len * 8;
pub fn draw(self: Self) void {
    for (Tool.array) |entry, n| {
        if (n == self.index) {
            w4.DRAW_COLORS.* = 0x14;
        } else {
            w4.DRAW_COLORS.* = 0x21;
        }

        w4.text(entry.name, 0, @intCast(i32, startAtY + n * 8));
    }
}
