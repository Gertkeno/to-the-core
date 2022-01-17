const w4 = @import("wasm4.zig");
const std = @import("std");

var layernamebuffer: [16]u8 = undefined;
var layername: []const u8 = layernamebuffer[0..7];
var currentlayer: u8 = 0;

fn set_layername(newlayer: u8) void {
    const names: []const []const u8 = &.{
        "Crust",
        "Lithosphere",
        "Asthenosphere",
        "Mantle",
        "Mesosphere",
        "Outer Core",
        "Inner Core",
    };

    const nameindex = newlayer / 9;
    if (nameindex >= names.len) {
        layername = "Winner!?";
    } else {
        layername = std.fmt.bufPrint(
            &layernamebuffer,
            "{s} {d}",
            .{ names[nameindex], newlayer % 9 + 1 },
        ) catch |err| @errorName(err);
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

pub fn draw(progress: i16, r: std.rand.Random) void {
    if (progress > 0) {
        const p2 = @divTrunc(progress, 4);
        for (w4.FRAMEBUFFER[0..320]) |*byte, n| {
            const x = n % 40;
            if (p2 >= x) {
                byte.* = r.int(u8);
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
