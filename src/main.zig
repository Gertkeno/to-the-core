const w4 = @import("wasm4.zig");
const Controller = @import("Controller.zig");

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

var controller1 = Controller{};
var xpos: i16 = 0;

const std = @import("std");

var rng = std.rand.DefaultPrng.init(0);
const r = rng.random();

const memory: *[58975]u8 = @intToPtr(*[58975]u8, 0x19A0);

export fn start() void {
    for (w4.PALETTE.*) |*pallet, n| {
        pallet.* = deeppallet[n];
    }

    //w4.trace(memory);
    //const ram = memory.allocator();
}

pub export const afunnystring: [*]const u8 = "Come find me! i'm not used anywhere";

export fn update() void {
    for (w4.FRAMEBUFFER[0..280]) |*byte| {
        byte.* = r.int(u8);
        byte.* |= 0b10101010;
    }

    w4.DRAW_COLORS.* = 0x02;
    w4.text("However", 55, 0);

    controller1.update(w4.GAMEPAD1.*);

    if (controller1.is_pressed(w4.BUTTON_1)) {
        w4.DRAW_COLORS.* = 0x34;
    } else if (controller1.is_held(w4.BUTTON_1)) {
        w4.DRAW_COLORS.* = 0x03;
    } else if (controller1.is_released(w4.BUTTON_1)) {
        w4.DRAW_COLORS.* = 0x43;
        w4.trace("nice release bud!");
    }

    xpos += 1;
    if (xpos > w4.CANVAS_SIZE) {
        xpos = -8;
    }

    w4.blit(&smiley, xpos, 76, 8, 8, w4.BLIT_1BPP);
    w4.text("Press X to blink", 16, 90);
}
