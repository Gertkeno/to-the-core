const w4 = @import("wasm4.zig");
const std = @import("std");

const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");

const Layer = @import("Layer.zig");
const Character = @import("Character.zig");
const LayerProgress = @import("LayerProgress.zig");
const Palette = @import("Palette.zig");
const Bank = @import("Bank.zig");

const Tutorial = @import("TutorialWorm.zig");
const MainMenu = @import("MainMenu.zig");
const SaveData = @import("SaveData.zig");

var controls = Controller{};

export var map = Layer{};
export var bank = Bank{};
export var player = Character{};

// 82715
var randombacker = std.rand.DefaultPrng.init(82724);
export var rng: std.rand.Random = undefined;
var mainMenu: ?MainMenu = MainMenu{};

export fn start() void {
    for (w4.PALETTE.*) |*palette, n| {
        palette.* = Palette.cards[n];
    }

    rng = randombacker.random();
    w4.SYSTEM_FLAGS.* = w4.SYSTEM_PRESERVE_FRAMEBUFFER;
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
    controls.update(w4.GAMEPAD1.*);

    if (mainMenu) |*mm| {
        if (mm.update(controls)) |newstate| {
            switch (newstate) {
                .@"New Game" => {
                    bank = Bank{};
                    LayerProgress.set_layer(0);
                    map.init_cave(0, rng);
                },
                .@"Load Game" => {
                    if (SaveData.read_save()) {
                        Tutorial.disable();
                    } else { // don't close the menu
                        return;
                    }
                },
            }

            mainMenu = null;
        }
        return;
    }

    LayerProgress.draw(bank.stockpile.drill >> Bank.DrillShift);
    map.draw_full();
    if (Tutorial.update_draw(&controls)) {
        return;
    }

    map.update();
    player.update(controls);

    map.draw_pickups();

    if (bank.stockpile.drill >> Bank.DrillShift < 161) {
        bank.stockpile.drill += bank.drillgen;
    } else {
        Tutorial.progression_trigger(.progress_layer);
    }

    player.draw();

    if (map.check_pickups(player.x >> 2, player.y >> 2)) |currency| {
        switch (currency) {
            .Mana => {
                bank.stockpile.mana += 1;
            },
            .Amber => {
                bank.stockpile.amber += 1;
                Tutorial.progression_trigger(.collect_amber);
            },
            .Housing => unreachable,

            .None => { // using this enum as a layer end collision check
                sfxNextLayer.play();
                if (bank.stockpile.amber < 6)
                    bank.stockpile.amber = 6;

                bank.stockpile.drill = 0;
                bank.drillgen = 0;
                LayerProgress.increment();
                LayerProgress.draw(0);

                player = Character{};
                map.init_cave(LayerProgress.get_current(), rng);
            },
        }

        SaveData.write_save();
    }
}
