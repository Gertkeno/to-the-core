const stoneBottom = [8]u8{
    0b00000000,
    0b00000000,
    0b00010001,
    0b01111011,
    0b11111111,
    0b11111111,
    0b11111110,
    0b11101111,
};

const stoneRight = [8]u8{
    0b00000001,
    0b00000011,
    0b00000001,
    0b00000001,
    0b00000011,
    0b00000011,
    0b00000101,
    0b00000001,
};

const stoneTop = [8]u8{
    0b11111110,
    0b01000100,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
};

const stoneLeft = [8]u8{
    0b10000000,
    0b10000000,
    0b11000000,
    0b10000000,
    0b10000000,
    0b10100000,
    0b11000000,
    0b11000000,
};

const stoneEmpty = [8]u8{
    0b00000000,
    0b00000000,
    0b00100000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000100,
    0b00000000,
};

const stones: []const [8]u8 = &.{
    stoneLeft,
    stoneRight,
    stoneTop,
    stoneBottom,
    stoneEmpty,
};

const emptyLeft = [8]u8{
    0b00000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000,
};

const emptyRight = [8]u8{
    0b00000000,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
};

const emptyTop = [8]u8{
    0b11110111,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
};

const emptyBottom = [8]u8{
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
};

const emptyEmpty = [8]u8{
    0b00000000,
    0b00000000,
    0b00000000,
    0b00010000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
};

const empties: []const [8]u8 = &.{
    emptyLeft,
    emptyRight,
    emptyTop,
    emptyBottom,
    emptyEmpty,
};

pub const Faces = packed struct {
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,

    pub fn bor(a: Faces, b: Faces) Faces {
        return @bitCast(@as(u4, @bitCast(a)) | @as(u4, @bitCast(b)));
    }

    pub fn bnot(a: Faces) Faces {
        return @bitCast(~@as(u4, @bitCast(a)));
    }
};

const w4 = @import("wasm4.zig");
const std = @import("std").mem;

fn bor_tile(face: Faces, tileset: []const [8]u8) i64 {
    const face_bits: u4 = @bitCast(face);
    var buffer: i64 = 0;
    inline for (.{ 1, 2, 4, 8 }, 0..) |bit, i| {
        if (face_bits & bit == 0) {
            buffer |= std.bytesAsValue(i64, &tileset[i]).*;
        }
    }

    if (buffer == 0) {
        // sometimes debug-unreachable crashes?? hard coded indecies?
        buffer |= std.bytesAsValue(i64, &tileset[4]).*;
    }

    return buffer;
}

pub fn blitstone(face: Faces, x: i32, y: i32) void {
    const buffer = bor_tile(face, stones);
    w4.blit(std.asBytes(&buffer), x, y, 8, 8, w4.BLIT_1BPP);
}

pub fn blitempty(face: Faces, x: i32, y: i32) void {
    const buffer = bor_tile(face, empties);
    w4.blit(std.asBytes(&buffer), x, y, 8, 8, w4.BLIT_1BPP);
}

pub const diamonds = [8]u8{
    0b00000000,
    0b01110100,
    0b00101110,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
};

pub const gems = [8]u8{
    0b00000000,
    0b00000010,
    0b00000100,
    0b00000000,
    0b01001000,
    0b00010000,
    0b00100100,
    0b00000000,
};
