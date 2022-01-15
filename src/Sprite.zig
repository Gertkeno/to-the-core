pub const stoneBottom = [8]u8{
    0b00000000,
    0b00000000,
    0b00010001,
    0b01111011,
    0b11111111,
    0b11111111,
    0b11111110,
    0b11101111,
};

pub const stoneRight = [8]u8{
    0b00000001,
    0b00000011,
    0b00000001,
    0b00000001,
    0b00000011,
    0b00000011,
    0b00000101,
    0b00000001,
};

pub const stoneTop = [8]u8{
    0b11111110,
    0b01000100,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
};

pub const stoneLeft = [8]u8{
    0b10000000,
    0b10000000,
    0b11000000,
    0b10000000,
    0b10000000,
    0b10100000,
    0b11000000,
    0b11000000,
};

const stones: []const [8]u8 = &.{
    stoneLeft,
    stoneRight,
    stoneTop,
    stoneBottom,
};

pub const Faces = packed struct {
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,
};

const w4 = @import("wasm4.zig");
const std = @import("std").mem;

pub fn blitstone(face: Faces, x: i32, y: i32) void {
    var buffer: u64 = 0;
    if (!face.left) {
        buffer |= std.bytesAsValue(u64, &stones[0]).*;
    }
    if (!face.right) {
        buffer |= std.bytesAsValue(u64, &stones[1]).*;
    }
    if (!face.up) {
        buffer |= std.bytesAsValue(u64, &stones[2]).*;
    }
    if (!face.down) {
        buffer |= std.bytesAsValue(u64, &stones[3]).*;
    }

    w4.blit(std.asBytes(&buffer), x, y, 8, 8, w4.BLIT_1BPP);
}
