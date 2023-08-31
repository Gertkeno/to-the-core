const Character = @import("Character.zig");
const Layer = @import("Layer.zig");
const map: *Layer = &Layer.map;

const Caveart = @import("Caveart.zig");

const Tutorial = @import("TutorialWorm.zig");
const Bank = @import("Bank.zig");
const bank: *Bank = &Bank.bank;
const Sound = @import("Sound.zig");
const w4 = @import("wasm4.zig");

fn direct_neighbors(index: usize, tile: Layer.Tiles) u2 {
    var count: u2 = 0;
    const neighbors = [_]i32{ -20, -1, 1, 20 };
    const sindex: i32 = @intCast(index);
    for (neighbors) |diff| {
        if (sindex + diff < 0 or sindex + diff > map.tiles.len)
            continue;

        const neighbor = map.tiles[@intCast(sindex + diff)];
        if (tile == .stone and (neighbor == .diamonds or neighbor == .gems or neighbor == .spring)) {
            count += 1;
        } else if (tile == .workshop and neighbor == .weavery) {
            count += 1;
        } else if (neighbor == tile) {
            count += 1;
        }
    }
    return count;
}

const icon_sell = [8]u8{
    0b00111100,
    0b01001010,
    0b11010001,
    0b00101000,
    0b00011100,
    0b00001010,
    0b01010011,
    0b00111100,
};

pub fn sell(index: usize, _: *Character) bool {
    const tile = &map.tiles[index];
    switch (tile.*) {
        .workshop => {
            if (bank.stockpile.worker > 0) {
                bank.stockpile.worker -= 1;
                bank.stockpile.gem += workshopCost << Bank.Ratio;
            } else {
                return false;
            }
        },
        .spring => {
            //bank.stockpile.mana += 1 << Bank.Ratio;
        },
        .empty,
        .stone,
        .spring,
        => {
            return false;
        },
    }
    tile.* = .empty;
    return true;
}

const brickBreak = Sound{
    .freq = .{ .start = 600, .end = 280 },
    .adsr = .{ .sustain = 10, .release = 10 },
    .mode = w4.TONE_NOISE,
    .volume = 45,
};

const icon_dig = [8]u8{
    0b00011100,
    0b01111110,
    0b10011011,
    0b00011001,
    0b00110000,
    0b00110000,
    0b01110000,
    0b01100000,
};

pub fn dig(index: usize, _: *Character) bool {
    if (bank.stockpile.crystal < 1)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .stone and tile.* != .gems)
        return false;

    bank.stockpile.crystal -= 1;
    if (tile.* == .gems)
        map.add_pickup(index, .Gem);

    brickBreak.play();
    tile.* = .empty;
    return true;
}

const sfxWorkshopLow = Sound{
    .freq = .{
        .start = 300,
    },
    .adsr = .{
        .sustain = 8,
        .release = 4,
    },
    .mode = w4.TONE_NOISE,
};

const sfxWorkshopHigh = Sound{
    .freq = .{
        .start = 500,
    },
    .adsr = .{
        .sustain = 8,
        .release = 4,
    },
    .mode = w4.TONE_PULSE2,
    .channel = w4.TONE_MODE2,
};

const icon_house = [8]u8{
    0b01100000,
    0b01111100,
    0b11111111,
    0b01111110,
    0b01010010,
    0b01110010,
    0b01110010,
    0b00000000,
};

const workshopCost = 4; // gem
pub fn build_workshop(index: usize, _: *Character) bool {
    if (bank.stockpile.gem < workshopCost)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .empty)
        return false;

    if (direct_neighbors(index, .workshop) >= 1)
        return false;

    bank.stockpile.worker += 2;
    sfxWorkshopLow.play();
    tile.* = .workshop;
    bank.stockpile.gem -= workshopCost;
    Tutorial.progression_trigger(.built_workshop);
    return true;
}

const sfxSpring = Sound{
    .freq = .{
        .start = 900,
        .end = 1400,
    },
    .adsr = .{
        .attack = 8,
    },
    .volume = 30,

    .mode = w4.TONE_PULSE1,
    .channel = w4.TONE_MODE2,
};

const springCost = 1; // worker
pub fn build_spring(index: usize, _: *Character) bool {
    if (bank.stockpile.worker < springCost)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .diamonds)
        return false;

    tile.* = .spring;
    bank.stockpile.worker -= 1;
    sfxSpring.play();
    Tutorial.progression_trigger(.built_spring);
    return true;
}

const icon_weavery = [8]u8{
    0b00101000,
    0b10010101,
    0b10101001,
    0b10010101,
    0b10101001,
    0b10010101,
    0b10000001,
    0b00000000,
};

const weaveryCost = 10; // Crystal
pub fn build_weavery(index: usize, _: *Character) bool {
    if (bank.stockpile.crystal < weaveryCost)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .workshop)
        return false;

    tile.* = .weavery;
    sfxWorkshopHigh.play();
    bank.stockpile.crystal -= weaveryCost;
    Tutorial.progression_trigger(.built_weavery);
    return true;
}

const icon_drill = [8]u8{
    0b01111110,
    0b00111100,
    0b00111100,
    0b00010000,
    0b00011000,
    0b00011000,
    0b00001000,
    0b00000000,
};

const drillCost = 4;
pub fn build_drill(index: usize, _: *Character) bool {
    if (bank.stockpile.worker < drillCost)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .empty)
        return false;

    if (direct_neighbors(index, .stone) >= 3) {
        bank.drillgen += 2;
        sfxWorkshopHigh.play();
    } else {
        bank.drillgen += 1;
        sfxWorkshopLow.play();
    }

    tile.* = .drill;
    bank.stockpile.worker -= drillCost;
    Tutorial.progression_trigger(.built_drill);
    return true;
}

const icon_teleport = [8]u8{
    0b00011000,
    0b00110100,
    0b00011000,
    0b00111100,
    0b10011001,
    0b01011010,
    0b10100101,
    0b01011010,
};

const sfxTeleport = Sound{
    .freq = .{
        .start = 100,
        .end = 500,
    },

    .adsr = .{
        .attack = 30,
    },

    .mode = w4.TONE_NOISE,
};
var teleporterPos: ?usize = null;
const teleportCost = 1;
pub fn teleport(index: usize, player: *Character) bool {
    if (bank.stockpile.gem < teleportCost)
        return false;
    _ = index;

    player.x = 82 << 2;
    player.y = 81 << 2;
    sfxTeleport.play();
    bank.stockpile.gem -= teleportCost;
    return true;
}

pub const Belt = struct {
    icon: *const [8]u8,
    func: *const fn (usize, *Character) bool,
    cost: u32,
    currency: Bank.CurrencyType,
    name: []const u8,
};

pub const array = [_]Belt{
    .{
        .icon = &icon_teleport,
        .func = teleport,
        .cost = teleportCost,
        .currency = Bank.CurrencyType.Gem,
        .name = "teleport",
    },
    .{
        .icon = &icon_weavery,
        .func = build_weavery,
        .cost = weaveryCost,
        .currency = Bank.CurrencyType.Crystal,
        .name = "weavery",
    },
    .{
        .icon = &Caveart.diamonds,
        .func = build_spring,
        .cost = springCost,
        .currency = Bank.CurrencyType.Worker,
        .name = "spring",
    },
    .{
        .icon = &icon_dig,
        .func = dig,
        .cost = 1,
        .currency = Bank.CurrencyType.Crystal,
        .name = "dig",
    },
    .{
        .icon = &icon_house,
        .func = build_workshop,
        .cost = workshopCost,
        .currency = Bank.CurrencyType.Gem,
        .name = "workshop",
    },
    .{
        .icon = &icon_drill,
        .func = build_drill,
        .cost = drillCost,
        .currency = Bank.CurrencyType.Worker,
        .name = "drill",
    },
};
