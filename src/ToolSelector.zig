const w4 = @import("wasm4.zig");

const Character = @import("Character.zig");
const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");
const Bank = @import("Bank.zig");
const Tool = @import("Tool.zig");
const Tutorial = @import("TutorialWorm.zig");

const tooltips: []const []const u8 = &.{
    @embedFile("tooltip/teleport.txt"),
    @embedFile("tooltip/weavery.txt"),
    @embedFile("tooltip/spring.txt"),
    @embedFile("tooltip/dig.txt"),
    @embedFile("tooltip/workshop.txt"),
    @embedFile("tooltip/drill.txt"),
};

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
index: usize = 3,

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
        } else {
            char.tool = Tool.array[self.index];
        }
        ticky.play();
        return true;
    } else if (controls.released.y and self.index < tooltips.len) {
        // display tutorial
        Tutorial.force_read(tooltips[self.index]);
    }

    return false;
}

const startAtY = 152 - Tool.array.len * 8;
const startAtX = 160 - 9 * 8;
pub fn draw(self: Self) void {
    for (Tool.array) |entry, n| {
        if (n == self.index) {
            w4.DRAW_COLORS.* = 0x14;
        } else {
            w4.DRAW_COLORS.* = 0x21;
        }

        const y = @intCast(i32, startAtY + n * 8);
        w4.blit(entry.icon, 160 - 8, y, 8, 8, w4.BLIT_1BPP);
        const x = @intCast(i32, 160 - 8 - (entry.name.len * 8));
        w4.text(entry.name, x, y);
    }

    if (Tool.array.len == self.index) {
        w4.DRAW_COLORS.* = 0x14;
    } else {
        w4.DRAW_COLORS.* = 0x21;
    }
    w4.text("none", 120, 152);
}
