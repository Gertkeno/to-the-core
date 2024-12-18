const w4 = @import("wasm4.zig");
const std = @import("std");

const Netplay = @import("Netplay.zig");
const Controller = @import("Controller.zig");
const Sound = @import("Sound.zig");

const Layer = @import("Layer.zig");
const map: *Layer = &Layer.map;
const Character = @import("Character.zig");
const LayerProgress = @import("LayerProgress.zig");
const Palette = @import("Palette.zig");
const Bank = @import("Bank.zig");
const bank: *Bank = &Bank.bank;

const Tutorial = @import("TutorialWorm.zig");
const MainMenu = @import("MainMenu.zig");
const SaveData = @import("SaveData.zig");

const gamepads = [4]*const u8{
    w4.GAMEPAD1,
    w4.GAMEPAD2,
    w4.GAMEPAD3,
    w4.GAMEPAD4,
};
var controls = [4]Controller{ .{}, .{}, .{}, .{} };

var players = [4]Character{
    .{ .color = 0x4023 },
    .{ .color = 0x4032 },
    .{ .color = 0x3024 },
    .{ .color = 0x3042 },
};
var active_players: usize = 1;

// 82715
var randombacker = std.rand.DefaultPrng.init(82724);
var rng: std.rand.Random = undefined;

var mainMenu: ?MainMenu = MainMenu.init(82724);

export fn start() void {
    for (w4.PALETTE, 0..) |*palette, n| {
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
    // poll all controller changes
    for (&controls, 0..) |*controller, n| {
        if (gamepads[n].* > 0) {
            active_players = @max(active_players, n + 1);
        }
        controller.update(gamepads[n].*);
    }

    // main menu and early return
    if (mainMenu) |*mm| {
        if (mm.update(controls[0])) |newstate| {
            switch (newstate) {
                .@"New Game" => {
                    randombacker.seed(mm.seed);
                    bank.* = Bank{};
                    LayerProgress.set_layer(0, rng);
                    map.init_cave(0, rng);
                },
                .@"Load Game" => {
                    if (SaveData.read_save()) {
                        map.rng = rng;
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

    // background draw map and title bar
    LayerProgress.draw(bank.stockpile.drill >> Bank.DrillShift, rng);
    map.draw_full();

    // single player only tutorial worm
    if (active_players == 1 and Tutorial.update_draw(&controls[0])) {
        return;
    }

    // most game logic updates
    map.update();
    for (players[0..active_players], 0..) |*player, n| {
        player.update(controls[n]);
    }

    if (bank.stockpile.drill >> Bank.DrillShift < 161) {
        bank.stockpile.drill += bank.drillgen;
    } else {
        Tutorial.progression_trigger(.progress_layer);
    }

    // draw gem and crystal pickups
    map.draw_pickups();

    // draw player and tool ui
    const drawingStockpile = for (players[0..active_players]) |player| {
        if (player.in_left_corner()) {
            break false;
        }
    } else true;

    for (players[0..active_players], 0..) |player, n| {
        if (drawingStockpile) {
            if (player.tool) |tool| {
                Character.draw_stockpile(tool, @intCast(n));
            }
        }

        player.draw();

        if (Netplay.enabled()) {
            if (n == Netplay.player()) {
                if (player.toolSelecting) |ts| {
                    ts.draw();
                }
            }
        } else {
            if (player.toolSelecting) |ts| {
                ts.draw();
            }
        }
    }

    // check gem and crystal pick ups
    for (players[0..active_players]) |player| {
        if (map.check_pickups(player.x >> 2, player.y >> 2)) |currency| {
            switch (currency) {
                .Crystal => {
                    bank.stockpile.crystal += 1;
                },
                .Gem => {
                    bank.stockpile.gem += 1;
                    Tutorial.progression_trigger(.collect_gem);
                },
                .Worker => unreachable,

                .None => { // using this enum as a layer end collision check
                    sfxNextLayer.play();
                    if (bank.stockpile.gem < 6)
                        bank.stockpile.gem = 6;

                    bank.stockpile.drill = 0;
                    bank.drillgen = 0;
                    LayerProgress.increment(rng);
                    LayerProgress.draw(0, rng);

                    for (players[0..active_players]) |*p| {
                        p.reset();
                    }
                    map.init_cave(LayerProgress.get_current(), rng);
                    if (LayerProgress.get_current() == 6) {
                        Tutorial.progression_trigger(.progress_core);
                    }
                },
            }

            SaveData.write_save();
        }
    }
}
