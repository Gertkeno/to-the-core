const w4 = @import("wasm4.zig");
const std = @import("std");

const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");
const Palette = @import("Palette.zig");

const Layer = @import("Layer.zig");
const LayerProgress = @import("LayerProgress.zig");
const Character = @import("Character.zig");
const Bank = @import("Bank.zig");

var controls = Controller{};

export var map = Layer{};
export var bank = Bank{};
var player = Character{
    .x = 320,
    .y = 320,
};

// 82715
var randombacker = std.rand.DefaultPrng.init(82724);
export var rng: std.rand.Random = undefined;

export fn start() void {
    for (w4.PALETTE.*) |*palette, n| {
        palette.* = Palette.cards[n];
    }

    rng = randombacker.random();
    w4.SYSTEM_FLAGS.* = w4.SYSTEM_PRESERVE_FRAMEBUFFER;

    map.init_cave(0, rng);
    LayerProgress.init();
}

export fn update() void {
    LayerProgress.draw(0);

    controls.update(w4.GAMEPAD1.*);
    map.draw_full();

    bank.update();
    player.update(controls);
    player.draw();

    if (false and controls.released.y) {
        map.init_cave(LayerProgress.get_current(), rng);
        LayerProgress.increment();
        LayerProgress.draw(0);
    }
}
