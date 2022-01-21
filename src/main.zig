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
export var player = Character{};

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
    LayerProgress.draw(bank.stockpile.drill >> Bank.DrillShift);

    if (bank.stockpile.drill >> Bank.DrillShift < 161) {
        bank.stockpile.drill += bank.drillgen;
    } else {
        bank.stockpile.drill = 0;
        LayerProgress.increment();
        LayerProgress.draw(0);

        player = Character{};
        map.init_cave(LayerProgress.get_current(), rng);
    }

    controls.update(w4.GAMEPAD1.*);
    map.draw_full();

    map.update();
    player.update(controls);

    map.draw_pickups();
    player.draw();

    if (map.check_pickups(player.x >> 2, player.y >> 2)) |currency| {
        switch (currency) {
            .Mana => {
                bank.stockpile.mana += 1;
            },
            .Amber => {
                bank.stockpile.amber += 1;
            },
            .None, .Housing => unreachable,
        }
    }
}
