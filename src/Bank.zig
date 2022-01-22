const Self = @This();
const std = @import("std");

pub const DrillShift = 9;

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

const DrawStruct = struct {
    width: i32,
    height: i32,
    flags: u32,
    array: [*]const u8,
};

pub const artAmber = DrawStruct{
    .width = 4,
    .height = 6,
    .flags = 1,
    .array = &[_]u8{ 0x02, 0x28, 0x68, 0x68, 0x6a, 0x96 },
};

pub const artMana = DrawStruct{
    .width = 4,
    .height = 6,
    .flags = 1,
    .array = &[_]u8{ 0x34, 0x34, 0xed, 0xda, 0x38, 0x38 },
};
