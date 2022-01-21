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
        .Mana => &gem,
        .Amber => &brick,
        .None, .Housing => unreachable,
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

//pub fn kill_to(self: *Self,
const DrawStruct = struct {
    width: i32,
    height: i32,
    flags: u32,
    array: [*]const u8,
};

// _1brick
const brick = DrawStruct{
    .width = 4,
    .height = 6,
    .flags = 1,
    .array = &[_]u8{ 0x02, 0x28, 0x68, 0x68, 0x6a, 0x96 },
};

// gem
const gem = DrawStruct{
    .width = 4,
    .height = 6,
    .flags = 1,
    .array = &[_]u8{ 0x34, 0x34, 0xed, 0xda, 0x38, 0x38 },
};
