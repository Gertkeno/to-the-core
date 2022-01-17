// animtion frames
const _1 = [6]u8{ 0xb6, 0xf3, 0x82, 0x3c, 0xbe, 0x38 };
const _2 = [6]u8{ 0xb7, 0xf2, 0x82, 0x3c, 0x3e, 0xac };
const _3 = [6]u8{ 0xb7, 0xf2, 0x80, 0x3e, 0x8e, 0xa2 };
const _4 = [6]u8{ 0xb6, 0xf3, 0x02, 0xbc, 0xbc, 0x8a };

const frames: []const [6]u8 = &.{
    _1, _2, _3, _4,
};

const crosshair = [8]u8{
    0b01110000,
    0b10000000,
    0b10000000,
    0b10001000,
    0b00010001,
    0b00000001,
    0b00000001,
    0b00001110,
};

const Self = @This();

const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");
const Layer = @import("Layer.zig");
const w4 = @import("wasm4.zig");
const math = @import("std").math;

const brickBreak = Sound{
    .freq = .{ .start = 600, .end = 280 },
    .adsr = .{ .sustain = 10, .release = 10 },
    .mode = w4.TONE_NOISE,
    .volume = 25,
};

extern var map: Layer;

x: i32 = 320,
y: i32 = 320,
animation: u8 = 0,
flipme: bool = false,
heldup: i2 = 0,

// I use a lot of bitshifts since x/y are not going to be negative but will be
// used in signed math, and I only want to divide by 4 (>>2) where player
// movement is sub-frame. For divisions by 32 (>>5) we convert player's
// subframe position to the 20x19 tilegrid

fn tool_tile_position(self: Self) struct { x: i32, y: i32 } {
    var xoffset: i32 = 8;
    if (self.heldup == 0) {
        xoffset += if (self.flipme) @as(i32, -32) else 28;
    }
    const toolx: i32 = math.clamp((self.x + xoffset) >> 5, 0, 19);
    const yoffset: i32 = 32 * @intCast(i32, self.heldup);
    const tooly: i32 = math.clamp((self.y + 12 - 32 + yoffset) >> 5, 0, 18);

    return .{
        .x = toolx,
        .y = tooly,
    };
}

fn draw_tool(self: Self) void {
    const tool = self.tool_tile_position();

    const flags = w4.BLIT_1BPP | if (self.animation & 8 != 0) w4.BLIT_FLIP_Y else 0;
    w4.DRAW_COLORS.* = 0x20;
    w4.blit(&crosshair, tool.x * 8, (tool.y + 1) * 8, 8, 8, flags);
}

pub fn draw(self: Self) void {
    w4.DRAW_COLORS.* = 0x4023;
    const flags = w4.BLIT_2BPP | if (self.flipme) w4.BLIT_FLIP_X else 0;
    w4.blit(&frames[self.animation >> 2], self.x >> 2, self.y >> 2, 4, 6, flags);

    self.draw_tool();
}

pub fn player_tile_position(self: Self) usize {
    const x: i32 = math.clamp((self.x + 8) >> 5, 0, 19);
    const y: i32 = math.clamp((self.y - 20) >> 5, 0, 18);

    return @intCast(usize, x + y * 20);
}

pub fn update(self: *Self, controls: Controller) void {
    if (controls.held.right) {
        self.x += 1;
        self.flipme = false;
        self.heldup = 0;
    } else if (controls.held.left) {
        self.x -= 1;
        self.flipme = true;
        self.heldup = 0;
    }

    { // x simple collision detection
        const y = @intCast(usize, math.clamp((self.y - 20) >> 5, 0, 18));
        const xl = @intCast(usize, math.clamp(self.x >> 5, 0, 19));
        const xr = @intCast(usize, math.clamp((self.x + 12) >> 5, 0, 19));
        if (self.x < 0 or map.tiles[xl + y * 20] != .empty) {
            self.x += 1;
        } else if (self.x > 160 << 2 or map.tiles[xr + y * 20] != .empty) {
            self.x -= 1;
        }
    }

    if (controls.held.up) {
        self.y -= 1;
    } else if (controls.held.down) {
        self.y += 1;
    }

    if (@bitCast(u8, controls.held) & 0b00110000 == 0) {
        self.heldup = if (controls.held.up) @as(i2, -1) else 0 + if (controls.held.down) @as(i2, 1) else 0;
    }

    { // y simple collision detection
        const yt = @intCast(usize, math.clamp((self.y - 20) >> 5, 0, 18));
        const yb = @intCast(usize, math.clamp((self.y - 12) >> 5, 0, 18));
        const x = @intCast(usize, math.clamp((self.x + 6) >> 5, 0, 19));

        if (self.y < 32 or map.tiles[x + yt * 20] != .empty) {
            self.y += 1;
        } else if (self.y > 160 << 2 or map.tiles[x + yb * 20] != .empty) {
            self.y -= 1;
        }
    }

    if (@bitCast(u8, controls.held) & 0b11110000 != 0) {
        self.animation += 1;
        if (self.animation >= (frames.len << 2)) {
            self.animation = 0;
        }
    }

    if (controls.released.x) {
        // use tool
        const tool = self.tool_tile_position();
        const tile = map.check_pos(tool.x, tool.y);
        if (tile == .stone) {
            map.set_tile(tool.x, tool.y, .empty);
            brickBreak.play();
        }
    } else if (controls.released.y) {
        // select tool
    }
}
