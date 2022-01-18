const Self = @This();
const std = @import("std");

const Ratio = 20;

pub const Currency = packed struct {
    mana: u32 = 0,
    amber: u32 = 0,
    drill: u32 = 0,
};

previousLayers: Currency = .{},
calculated: Currency = .{},
stockpile: Currency = .{},

pub fn update(self: *Self) void {
    self.stockpile.mana = std.math.min(999 << Ratio, self.stockpile.mana + self.calculated.mana + self.previousLayers.mana);
    self.stockpile.amber = std.math.min(999 << Ratio, self.stockpile.amber + self.calculated.amber + self.previousLayers.amber);
    self.stockpile.dril = std.math.min(160 << Ratio, self.stockpile.dril + self.calculated.dril + self.previousLayers.dril);
}

pub fn at_ratio(comptime f: f64) u32 {
    return @as(u32, f * (1 << 20));
}
