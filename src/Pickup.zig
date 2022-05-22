const w4 = @import("wasm4.zig");

const math = @import("std").math;
const Bank = @import("Bank.zig");

x: i32,
y: i32,

animationTime: u16 = 0,
currency: Bank.CurrencyType,

const Self = @This();

pub fn init_index(index: usize, kind: Bank.CurrencyType) Self {
    const x = index % 20;
    const y = index / 20;

    return init_xy(x * 8, y * 8, kind);
}

pub fn init_xy(x: i32, y: i32, kind: Bank.CurrencyType) Self {
    return Self{
        .x = x,
        .y = y,
        .currency = kind,
    };
}

fn jump_anim_offset(time: u16) i32 {
    if (time > 50) {
        return 0;
    } else {
        return (time % 20) / 8;
    }
}

const Size = 4;
pub fn draw(self: Self) void {
    const x = self.x;
    const y = self.y;

    const sprite = switch (self.currency) {
        .Crystal => &Bank.artCrystal,
        .Gem => &Bank.artGem,
        .None, .Worker => unreachable,
    };
    const jump = jump_anim_offset(self.animationTime);
    w4.blit(sprite.array, x, y + jump, sprite.width, sprite.height, sprite.flags);
}

pub fn contact(self: Self, x: i32, y: i32) bool {
    if (x + 4 < self.x or x > self.x + 4) {
        return false;
    } else if (y + 6 < self.y or y > self.y + 4) {
        return false;
    }

    return true;
}

pub fn update(self: *Self) void {
    self.animationTime +%= 1;
}
