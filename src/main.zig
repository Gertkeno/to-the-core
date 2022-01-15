const w4 = @import("wasm4.zig");
const std = @import("std");
const ram = @import("ram.zig").allocator;

const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");
const Pallet = @import("Pallet.zig");
const Sprite = @import("Sprite.zig");

const Layer = @import("Layer.zig");

var controls = Controller{};
var xpos: i16 = 0;

var layer = Layer{};

var rng = std.rand.DefaultPrng.init(0);
const r = rng.random();

export fn start() void {
    for (w4.PALETTE.*) |*pallet, n| {
        pallet.* = Pallet.cards[n];
    }

    for (layer.tiles) |*tile| {
        tile.* = @intToEnum(Layer.Tiles, r.uintLessThan(u4, 3));
    }

    //w4.SYSTEM_FLAGS.* = w4.SYSTEM_PRESERVE_FRAMEBUFFER;

    //w4.trace(memory);
    //const ram = memory.allocator();
}

fn title_bar(progress: i16) void {
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
    w4.text("However", 55, 0);
}

const brickBreak = Sound{
    .freq = .{ .start = 600, .end = 280 },
    .adsr = .{ .sustain = 10, .release = 10 },
    .mode = w4.TONE_NOISE,
    .volume = 25,
};

export fn update() void {
    title_bar(xpos);

    //w4.DRAW_COLORS.* = 0x1234;
    //w4.blit(&cats, 0, 7, 160, 153, w4.BLIT_2BPP);

    controls.update(w4.GAMEPAD1.*);

    if (controls.held.right) {
        xpos += 1;
    } else if (controls.held.left) {
        xpos -= 1;
    }

    if (controls.released.y) {
        brickBreak.play();
        for (layer.tiles) |*tile| {
            tile.* = @intToEnum(Layer.Tiles, r.uintLessThan(u4, 2));
        }
    }

    w4.DRAW_COLORS.* = 0x43;
    layer.draw();
    //Sprite.blitstone(@bitCast(Sprite.Faces, @as(u4, 0b1101)), xpos, 76);
    //w4.blit(&Sprite.stoneBottom, xpos, 76, 8, 8, w4.BLIT_1BPP);
    w4.text("Press X to blink", 16, 90);
}
