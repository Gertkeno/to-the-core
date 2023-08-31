const tone = @import("wasm4.zig").tone;
const std = @import("std");
const Self = @This();

freq: packed struct {
    start: u16,
    end: u16 = 0,
},

adsr: packed struct {
    sustain: u8 = 0,
    release: u8 = 4,
    decay: u8 = 0,
    attack: u8 = 0,
} = .{},

volume: u8 = 75,

channel: u8 = 2,
mode: u8 = 0,

pub fn play(self: Self) void {
    const freq: u32 = @bitCast(self.freq);
    const adsr: u32 = @bitCast(self.adsr);
    const flags = self.channel | self.mode;

    tone(freq, adsr, self.volume, flags);
}
