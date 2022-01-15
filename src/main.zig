const w4 = @import("wasm4.zig");
const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");

const ram = @import("ram.zig").allocator;
const cats = @import("sushi_cats.zig").sushi_cats;

const deeppallet = [4]u32{
    0xf7e7c6,
    0xd68e49,
    0xa63725,
    0x331e50,
};
const mintpallet = [4]u32{
    0xc4f0c2,
    0x5ab9a8,
    0x1e606e,
    0x2d1b00,
};
const cardspallet = [4]u32{
    0xf0f0f0,
    0x8f9bf6,
    0xab4646,
    0x161616,
};

const smiley = [8]u8{
    0b11101111,
    0b11100111,
    0b11100111,
    0b11100111,
    0b11100111,
    0b10100101,
    0b11000011,
    0b11100111,
};

var controls = Controller{};
var xpos: i16 = 0;

const std = @import("std");

var rng = std.rand.DefaultPrng.init(0);
const r = rng.random();

export fn start() void {
    for (w4.PALETTE.*) |*pallet, n| {
        pallet.* = cardspallet[n];
    }

    //w4.trace(memory);
    //const ram = memory.allocator();
}

fn title_bar(progress: i16) void {
    if (progress > 0) {
        const p2 = progress >> 2;
        for (w4.FRAMEBUFFER[0..280]) |*byte, n| {
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

const bleep = Sound{
    .freq = .{ .start = 400, .end = 700 },
    .adsr = .{ .sustain = 15 },
};

export fn update() void {
    title_bar(xpos);

    w4.DRAW_COLORS.* = 0x1234;
    w4.blit(&cats, 0, 7, 160, 153, w4.BLIT_2BPP);

    controls.update(w4.GAMEPAD1.*);

    if (controls.held.right) {
        xpos += 1;
    } else if (controls.held.left) {
        xpos -= 1;
    }

    if (controls.released.y) {
        bleep.play();
    }

    w4.DRAW_COLORS.* = 0x02;
    w4.blit(&smiley, xpos, 76, 8, 8, w4.BLIT_1BPP);
    w4.text("Press X to blink", 16, 90);
}
