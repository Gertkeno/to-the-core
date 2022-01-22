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

const sfxNextLayer = Sound{
    .freq = .{
        .start = 800,
        .end = 100,
    },
    .adsr = .{
        .attack = 10,
        .decay = 10,
        .sustain = 30,
        .release = 10,
    },

    .volume = 80,
    .mode = w4.TONE_NOISE,
    .channel = w4.TONE_MODE2,
};

export fn update() void {
    LayerProgress.draw(bank.stockpile.drill >> Bank.DrillShift);

    controls.update(w4.GAMEPAD1.*);
    map.draw_full();

    map.update();
    player.update(controls);

    map.draw_pickups();

    if (bank.stockpile.drill >> Bank.DrillShift < 161) {
        bank.stockpile.drill += bank.drillgen;
    } else {
        for (w4.FRAMEBUFFER[6280..6400]) |*byte, n| {
            const x = n % 40;
            byte.* = switch (n / 40 + ((x + map.frameCount / 16) & 1) % 4) { // finish line effect
                3 => 0xFF,
                2 => 0b10101010,
                1 => 0b01010101,
                0 => 0,
                else => unreachable,
            };
        }
    }

    player.draw();

    if (map.check_pickups(player.x >> 2, player.y >> 2)) |currency| {
        switch (currency) {
            .Mana => {
                bank.stockpile.mana += 1;
            },
            .Amber => {
                bank.stockpile.amber += 1;
            },
            .Housing => unreachable,

            .None => { // using this enum as a layer end collision check
                sfxNextLayer.play();
                bank.stockpile.drill = 0;
                bank.drillgen = 0;
                LayerProgress.increment();
                LayerProgress.draw(0);

                player = Character{};
                map.init_cave(LayerProgress.get_current(), rng);
            },
        }
    }
}
