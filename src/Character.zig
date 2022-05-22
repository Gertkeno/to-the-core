const w4 = @import("wasm4.zig");
const std = @import("std");

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

const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");
const Bank = @import("Bank.zig");
const Layer = @import("Layer.zig");
const ToolSelector = @import("ToolSelector.zig");
const Belt = @import("Tool.zig").Belt;

extern var map: Layer;
extern var bank: Bank;

const SubRatio = 2;
const TileRatio = SubRatio + 3;

const Self = @This();

x: i32 = 82 << SubRatio,
y: i32 = 81 << SubRatio,
walkanimation: u8 = 4,
toolanimation: u8 = 0,
toolerror: ?u8 = null,
flipme: bool = false,
heldup: i2 = 0,

toolSelecting: ?ToolSelector = null,
tool: ?Belt = null,

var toolTextBuffer: [7]u8 = undefined;

fn tool_tip_stringify(mstock: u32, mcost: u32) []const u8 {
    var cost = mcost;
    var index: usize = 6;
    while (cost > 0) {
        toolTextBuffer[index] = '0' + @intCast(u8, cost % 10);
        index -= 1;
        cost /= 10;
    }

    toolTextBuffer[index] = '/';
    index -= 1;

    if (mstock == 0) {
        toolTextBuffer[index] = '0';
        index -= 1;
    } else {
        var stock = mstock;
        while (stock > 0) {
            toolTextBuffer[index] = '0' + @intCast(u8, stock % 10);
            index -= 1;
            stock /= 10;
        }
    }

    const output = toolTextBuffer[index + 1 ..];
    return output;
}

// I use a lot of bitshifts since x/y are not going to be negative but will be
// used in signed std.math, and I only want to divide by 4 (>>2) where player
// movement is sub-frame. For divisions by 32 (>>5) we convert player's
// subframe position to the 20x19 tilegrid

fn tool_tile_position(self: Self) struct { x: i32, y: i32 } {
    var xoffset: i32 = 8;
    if (self.heldup == 0) {
        xoffset += if (self.flipme) @as(i32, -32) else 28;
    }
    var toolx: i32 = (self.x + xoffset) >> TileRatio;
    if (toolx < 0) {
        toolx = 19;
    } else if (toolx > 19) {
        toolx = 0;
    }
    const yoffset: i32 = 32 * @intCast(i32, self.heldup);
    const tooly: i32 = std.math.clamp((self.y + 12 - 32 + yoffset) >> TileRatio, 0, 18);

    return .{
        .x = toolx,
        .y = tooly,
    };
}

fn draw_tool(self: Self) void {
    const tool = self.tool_tile_position();

    // crosshair
    const flags = w4.BLIT_1BPP | if (self.toolanimation & 8 != 0) w4.BLIT_FLIP_Y else 0;
    if (self.toolerror != null and self.toolerror.? & 4 != 0) {
        w4.DRAW_COLORS.* = 0x13;
    } else {
        w4.DRAW_COLORS.* = 0x20;
    }
    w4.blit(&crosshair, tool.x * 8, (tool.y + 1) * 8, 8, 8, flags);

    // stockpile check //
    w4.DRAW_COLORS.* = switch (self.tool.?.currency) {
        .Crystal => 0x21,
        .Gem => 0x31,
        .Worker => 0x41,
        .None => unreachable,
    };

    const xflip = tool.x < 6 and tool.y > 11;
    const xflipoffset = if (xflip) @as(i32, 152) else 0;
    w4.blit(self.tool.?.icon, xflipoffset, 152, 8, 8, w4.BLIT_1BPP);
    if (self.tool.?.currency != .None) {
        const instock = switch (self.tool.?.currency) {
            .Crystal => bank.stockpile.crystal,
            .Gem => bank.stockpile.gem,
            .Worker => bank.stockpile.worker,
            .None => unreachable,
        };

        const tooltext = tool_tip_stringify(instock, self.tool.?.cost);

        if (xflip) {
            const offset = @intCast(i32, 152 - tooltext.len * 8);
            w4.text(tooltext, offset, 152);
        } else {
            w4.text(tooltext, 8, 152);
        }
    }
}

pub fn draw(self: Self) void {
    w4.DRAW_COLORS.* = 0x4023;
    const flags = w4.BLIT_2BPP | if (self.flipme) w4.BLIT_FLIP_X else 0;

    const frame = &frames[self.walkanimation / 4];
    w4.blit(frame, self.x >> SubRatio, self.y >> SubRatio, 4, 6, flags);

    if (self.toolSelecting) |ts| {
        ts.draw();
    } else if (self.tool != null) {
        self.draw_tool();
    }
}

pub fn player_tile_position(self: Self) usize {
    const x: i32 = std.math.clamp((self.x + 8) >> TileRatio, 0, 19);
    const y: i32 = std.math.clamp((self.y - 20) >> TileRatio, 0, 18);

    return @intCast(usize, x + y * 20);
}

const toolfail = Sound{
    .freq = .{
        .start = 200,
        .end = 1600,
    },
    .adsr = .{
        .sustain = 6,
        .attack = 10,
    },
    .volume = 60,
    .mode = w4.TONE_TRIANGLE,
};

pub fn update(self: *Self, controls: Controller) void {
    if (self.toolSelecting) |*ts| {
        if (ts.selecting(self, controls)) {
            self.toolSelecting = null;
            self.toolerror = null;
        }
        return;
    }

    self.toolanimation +%= 1;
    if (self.toolerror) |*tr| {
        tr.* += 1;
        if (tr.* == 45) {
            self.toolerror = null;
        }
    }

    const quicky = (self.y - 20) >> TileRatio;
    if (controls.held.right) {
        self.x += 1;
        if (self.x + (4 << SubRatio) > 20 << TileRatio and map.walkable(0, quicky)) {
            self.x = 0;
        }
        self.flipme = false;
        self.heldup = 0;
    } else if (controls.held.left) {
        self.x -= 1;
        if (self.x < 0 and map.walkable(19, quicky)) {
            self.x = 20 << TileRatio;
        }
        self.flipme = true;
        self.heldup = 0;
    }

    { // x simple collision detection //
        const y = std.math.clamp((self.y - 20) >> TileRatio, 0, 18);
        const xl = std.math.clamp(self.x >> TileRatio, 0, 19);
        const xr = std.math.clamp((self.x + 12) >> TileRatio, 0, 19);
        if (self.x < 0 or !map.walkable(xl, y)) {
            self.x += 2;
        } else if (self.x > (156 << 2) + 2 or !map.walkable(xr, y)) {
            self.x -= 2;
        }
    }

    if (controls.held.up) {
        self.y -= 1;
        self.heldup = -1;
    } else if (controls.held.down) {
        self.y += 1;
        self.heldup = 1;
    }

    { // y simple collision detection //
        const yt = std.math.clamp((self.y - 20) >> TileRatio, 0, 18);
        const yb = std.math.clamp((self.y - 12) >> TileRatio, 0, 18);
        const x = std.math.clamp((self.x + 6) >> TileRatio, 0, 19);

        if (self.y < 32 or !map.walkable(x, yt)) {
            self.y += 2;
        } else if (self.y > (154 << 2) + 2 or !map.walkable(x, yb)) {
            self.y -= 2;
        }
    }

    if (@bitCast(u8, controls.held) & 0b11110000 != 0) {
        self.walkanimation += 1;
        if (self.walkanimation >= (frames.len * 4)) {
            self.walkanimation = 0;
        }
    }

    if (controls.released.x and self.tool != null) {
        // use tool
        const tool = self.tool_tile_position();
        const tindex = @intCast(usize, tool.x + tool.y * 20);
        if (!self.tool.?.func(tindex)) {
            if (self.toolerror == null) {
                self.toolerror = 0;
                toolfail.play();
            }
        }
    } else if (controls.released.y) {
        self.toolSelecting = ToolSelector{};
    }
}
