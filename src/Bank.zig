const Self = @This();
const std = @import("std");

pub const CurrencyType = enum { Mana, Amber, Housing, None };

pub const Currency = struct {
    mana: u32 = 0,
    amber: u32 = 0,
    housing: u32 = 0,
    drill: u32 = 0,
};

stockpile: Currency = .{
    .mana = 8,
    .amber = 2,
},

pub fn at_ratio(comptime f: f64) u32 {
    return @floatToInt(u32, f * (1 << 20));
}

pub fn per_second(comptime f: f64) u32 {
    return at_ratio(f / 60);
}
