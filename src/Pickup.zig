const w4 = @import("wasm4.zig");

const math = @import("std").math;
const Bank = @import("Bank.zig");

x: i32,
y: i32,

animationTime: u8 = 0,
state: enum {
    Active,
    Dead,
},
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
        .state = .Active,
        .currency = kind,
    };
}

fn jump_anim_offset(time: u8) i32 {
    if (time > 50) {
        return 0;
    } else {
        return (time % 20) / 4;
    }
}

const Size = 4;
pub fn draw(self: Self) void {
    const x = self.x;
    const y = self.y;

    if (self.state == .Active) {
        const sprite: [*]const u8 = switch (self.currency) {
            .Mana => &manacrystal,
            .Amber => &amber,
            else => unreachable,
        };
        const jump = jump_anim_offset(self.animationTime);
        w4.blit(sprite, x, y + jump, Size, Size, w4.BLIT_2BPP);
    } else {
        const index = @intCast(usize, x + y * 160);
        w4.FRAMEBUFFER[index] = 0x8F;
        //
    }
}

pub fn contact(self: Self, x: i32, y: i32) bool {
    if (x < self.x or x > self.x + Size) {
        return false;
    } else if (y < self.y or y > self.y + Size) {
        return false;
    }

    return true;
}

pub fn update(self: *Self) void {
    self.animationTime += 1;
}

//pub fn kill_to(self: *Self,

// manacrystal
const manacrystal_width = 4;
const manacrystal_height = 4;
const manacrystal_flags = 1; // BLIT_2BPP
const manacrystal = [4]u8{ 0x92, 0x7c, 0x72, 0x92 };
// amber
const amber_width = 4;
const amber_height = 4;
const amber_flags = 1; // BLIT_2BPP
const amber = [4]u8{ 0x92, 0x72, 0xf4, 0xb0 };
