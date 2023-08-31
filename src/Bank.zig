const Self = @This();
pub var bank = Self{};
const std = @import("std");

pub const DrillShift = 9;

pub const CurrencyType = enum { Crystal, Gem, Worker, None };
pub const Currency = struct {
    crystal: u32 = 0,
    gem: u32 = 0,
    worker: u32 = 0,
    drill: u32 = 0,
};

stockpile: Currency = .{
    .crystal = 8,
    .gem = 2,
},
drillgen: u32 = 0,

const DrawStruct = struct {
    width: u32,
    height: u32,
    flags: u32,
    array: [*]const u8,
};

pub const artGem = DrawStruct{
    .width = 4,
    .height = 6,
    .flags = 1,
    .array = &[_]u8{ 0x02, 0x28, 0x68, 0x68, 0x6a, 0x96 },
};

pub const artCrystal = DrawStruct{
    .width = 4,
    .height = 6,
    .flags = 1,
    .array = &[_]u8{ 0x34, 0x34, 0xed, 0xda, 0x38, 0x38 },
};
