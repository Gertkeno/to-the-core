const Self = @This();
const std = @import("std");

// 15 seconds for 1 point of 160, about 30 minutes with 1 drill going
pub const DrillShift = 10;

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
drillgen: u32 = 0,
