const Layer = @import("Layer.zig");
const Bank = @import("Bank.zig");
const Sound = @import("Sound.zig");
const w4 = @import("wasm4.zig");

extern var bank: Bank;
extern var map: Layer;

const icon_sell = [8]u8{
    0b00111100,
    0b01001010,
    0b11010001,
    0b00101000,
    0b00011100,
    0b00001010,
    0b01010011,
    0b00111100,
};

const resaleValue = [_]u32{
    0, 0, 0, 1,
};

pub fn sell(index: usize) bool {
    const tile = &map.tiles[index];
    const resale = resaleValue[@enumToInt(tile.*)];
    if (resale != 0) {
        tile.* = .empty;
        if (resale & 0x80000000 == 0) {
            bank.stockpile.mana += resale << Bank.Ratio;
        } else {
            bank.stockpile.amber += (resale & 0x80000000) << Bank.Ratio;
        }
        return true;
    } else {
        return false;
    }
}

const brickBreak = Sound{
    .freq = .{ .start = 600, .end = 280 },
    .adsr = .{ .sustain = 10, .release = 10 },
    .mode = w4.TONE_NOISE,
    .volume = 45,
};

const icon_dig = [8]u8{
    0b00011100,
    0b01111110,
    0b10011011,
    0b00011001,
    0b00110000,
    0b00110000,
    0b01110000,
    0b01100000,
};

pub fn dig(index: usize) bool {
    const tile = &map.tiles[index];
    switch (tile.*) {
        .stone => {
            tile.* = .empty;
            bank.stockpile.amber += Bank.at_ratio(1);
            brickBreak.play();
            return true;
        },
        else => {
            return false;
        },
    }
}

pub const Belt = struct {
    icon: *const [8]u8,
    func: fn (usize) bool,
    name: []const u8,
};

pub const array = [_]Belt{
    .{
        .icon = &icon_dig,
        .func = dig,
        .name = "dig",
    },
    .{
        .icon = &icon_sell,
        .func = sell,
        .name = "sell",
    },
};
