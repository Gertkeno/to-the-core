const w4 = @import("wasm4.zig");
const std = @import("std");
const Palette = @import("Palette.zig");

var layernamebuffer: [16]u8 = undefined;
var layername: []const u8 = layernamebuffer[0..7];
var currentlayer: u8 = 0;

const names: []const []const u8 = &.{
    "Crust",
    "Lithosphere",
    "Asthenosphere",
    "Mantle",
    "Mesosphere",
    "Outer Core",
    "Inner Core",
};

const palette: []const [4]u32 = &.{
    Palette.mint,
    Palette.gb,
    Palette.coldfire,
    Palette.cards,
    Palette.deep,
    Palette.spacehaze,
    Palette.halloween,
};

extern const rng: std.rand.Random;

fn set_layername(newlayer: u8) void {
    const nameindex = newlayer / 9;
    std.mem.set(u8, w4.FRAMEBUFFER[0..320], 0);
    if (nameindex >= names.len) {
        layername = "Winner!?";

        const npalette = palette[newlayer % 7];
        for (w4.PALETTE.*) |*p, n| {
            p.* = npalette[n];
        }
    } else {
        const layertype = names[nameindex];
        std.mem.copy(u8, &layernamebuffer, layertype);
        layernamebuffer[layertype.len] = ' ';
        layernamebuffer[layertype.len + 1] = '0' + (newlayer % 9 + 1);

        layername = layernamebuffer[0 .. layertype.len + 2];

        const npalette = palette[nameindex];
        for (w4.PALETTE.*) |*p, n| {
            p.* = npalette[n];
        }
    }
}

pub fn init() void {
    set_layername(0);
}

pub fn increment() void {
    if (currentlayer < 255) {
        currentlayer += 1;
        set_layername(currentlayer);
    }
}

pub fn draw(progress: i16) void {
    if (progress > 0) {
        rng.bytes(w4.FRAMEBUFFER[0..320]);

        const p2 = @divTrunc(progress, 4);
        for (w4.FRAMEBUFFER[0..320]) |*byte, n| {
            const x = n % 40;
            if (p2 >= x) {
                byte.* |= 0b10101010;

                if (p2 == x) {
                    const m4: i16 = @mod(progress, 4);
                    byte.* &= switch (m4) {
                        0 => 0b00000000,
                        1 => 0b00000011,
                        2 => 0b00011111,
                        3 => 0b01111111,
                        else => @as(u8, 0xff),
                    };
                }
            } else {
                byte.* = 0b00000000;
            }
        }
    }

    w4.DRAW_COLORS.* = 0x02;
    const x = @intCast(i32, 80 - (layername.len * 4));
    w4.text(layername, x, 0);
}
