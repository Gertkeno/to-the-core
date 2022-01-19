const Self = @This();
const std = @import("std");

pub const Ratio = 20;

pub const CurrencyType = enum { Mana, Amber, Housing, None };

pub const Currency = struct {
    mana: u32 = 0,
    amber: u32 = 0,
    housing: u32 = 0,
    drill: u32 = 0,
};

previousLayers: Currency = .{},
calculated: Currency = .{},
stockpile: Currency = .{
    .mana = 8 << Ratio,
    .amber = 2 << Ratio,
},

pub fn update(self: *Self) void {
    self.stockpile.mana = std.math.min(999 << Ratio, self.stockpile.mana + self.calculated.mana + self.previousLayers.mana);
    self.stockpile.amber = std.math.min(999 << Ratio, self.stockpile.amber + self.calculated.amber + self.previousLayers.amber);
    self.stockpile.drill = std.math.min(160 << Ratio, self.stockpile.drill + self.calculated.drill);
}

pub fn at_ratio(comptime f: f64) u32 {
    return @floatToInt(u32, f * (1 << 20));
}

pub fn per_second(comptime f: f64) u32 {
    return at_ratio(f / 60);
}
