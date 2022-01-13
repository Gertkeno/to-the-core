const w4 = @import("wasm4.zig");
const Controller = @import("Controller.zig");

const ram = @import("ram").allocator;

const creampallet = [4]u32{
    0xf9a875,
    0xfff6d3,
    0xeb6b6f,
    0x7c3f58,
};
const deeppallet = [4]u32{
    0xf7e7c6,
    0xd68e49,
    0xa63725,
    0x331e50,
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
        pallet.* = deeppallet[n];
    }

    //w4.trace(memory);
    //const ram = memory.allocator();
}

fn title_bar(health: i16) void {
    const hblock = @divTrunc(health, 4);
    for (w4.FRAMEBUFFER[0..280]) |*byte, n| {
        if (hblock >= n % 40) {
            byte.* = r.int(u8);
            byte.* |= 0b10101010;

            if (hblock == n % 40) {
                const m4: i16 = @mod(health, 4);
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

    w4.DRAW_COLORS.* = 0x4102;
    w4.text("However", 55, 0);
}

export fn update() void {
    title_bar(158);

    controls.update(w4.GAMEPAD1.*);

    if (controls.is_held(w4.BUTTON_1)) {
        xpos += 1;
    }

    if (xpos > w4.CANVAS_SIZE) {
        xpos = -8;
    }

    w4.blit(&smiley, xpos, 76, 8, 8, w4.BLIT_1BPP);
    w4.text("Press X to blink", 16, 90);
}
