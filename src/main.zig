const w4 = @import("wasm4.zig");
const std = @import("std");

const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");
const Palette = @import("Palette.zig");

const Layer = @import("Layer.zig");
const LayerProgress = @import("LayerProgress.zig");
const Character = @import("Character.zig");

var controls = Controller{};

export var map = Layer{};
var player = Character{
    .x = 320,
    .y = 320,
};

var rng = std.rand.DefaultPrng.init(0);
const r = rng.random();

export fn start() void {
    for (w4.PALETTE.*) |*palette, n| {
        palette.* = Palette.cards[n];
    }

    w4.SYSTEM_FLAGS.* = w4.SYSTEM_PRESERVE_FRAMEBUFFER;

    map.init_cave(r);
    LayerProgress.init();
}

export fn update() void {
    LayerProgress.draw(6, r);

    controls.update(w4.GAMEPAD1.*);
    map.draw();

    player.update(controls);
    player.draw();

    if (controls.released.y) {
        map.init_cave(r);
        LayerProgress.increment();
    }
}
