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

pub const stoneEmpty = [8]u8{
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

pub const emptyLeft = [8]u8{
    0b00000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000,
};

pub const emptyRight = [8]u8{
    0b00000000,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
    0b00000001,
};

pub const emptyTop = [8]u8{
    0b11110111,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
};

pub const emptyBottom = [8]u8{
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
};

pub const emptyEmpty = [8]u8{
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
};

const w4 = @import("wasm4.zig");
const std = @import("std").mem;

fn bor_tile(face: Faces, tileset: []const [8]u8) u64 {
    var buffer: u64 = 0;
    if (!face.left) {
        buffer |= std.bytesAsValue(u64, &tileset[0]).*;
    }
    if (!face.right) {
        buffer |= std.bytesAsValue(u64, &tileset[1]).*;
    }
    if (!face.up) {
        buffer |= std.bytesAsValue(u64, &tileset[2]).*;
    }
    if (!face.down) {
        buffer |= std.bytesAsValue(u64, &tileset[3]).*;
    }

    if (buffer == 0) {
        buffer |= std.bytesAsValue(u64, &tileset[4]).*;
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