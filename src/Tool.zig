const Character = @import("Character.zig");
const Layer = @import("Layer.zig");

const Caveart = @import("Caveart.zig");

const Bank = @import("Bank.zig");
const Sound = @import("Sound.zig");
const w4 = @import("wasm4.zig");

extern var bank: Bank;
extern var map: Layer;
extern var player: Character;

fn direct_neighbors(index: usize, tile: Layer.Tiles) u2 {
    var count: u2 = 0;
    const neighbors = [_]i32{ -20, -1, 1, 20 };
    const sindex = @intCast(i32, index);
    for (neighbors) |diff| {
        if (sindex + diff < 0 or sindex + diff > map.tiles.len)
            continue;

        const neighbor = map.tiles[@intCast(usize, sindex + diff)];
        if (tile == .stone and (neighbor == .spring or neighbor == .deposit)) {
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

pub fn sell(index: usize) bool {
    const tile = &map.tiles[index];
    switch (tile.*) {
        .housing => {
            if (bank.stockpile.housing > 0) {
                bank.stockpile.housing -= 1;
                bank.stockpile.amber += housingCost << Bank.Ratio;
            } else {
                return false;
            }
        },
        .siphon => {
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

pub fn dig(index: usize) bool {
    if (bank.stockpile.mana < 1)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .stone and tile.* != .deposit)
        return false;

    bank.stockpile.mana -= 1;
    if (tile.* == .deposit)
        map.add_pickup(index, .Amber);

    brickBreak.play();
    tile.* = .empty;
    return true;
}

const sfxHousingLow = Sound{
    .freq = .{
        .start = 300,
    },
    .adsr = .{
        .sustain = 8,
        .release = 4,
    },
    .mode = w4.TONE_NOISE,
};

const sfxHousingHigh = Sound{
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

const housingCost = 4; // amber
pub fn build_housing(index: usize) bool {
    if (bank.stockpile.amber < housingCost)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .empty)
        return false;

    tile.* = .housing;
    if (direct_neighbors(index, .stone) >= 2) {
        bank.stockpile.housing += 2;
        sfxHousingHigh.play();
    } else {
        bank.stockpile.housing += 1;
        sfxHousingLow.play();
    }
    bank.stockpile.amber -= housingCost;
    return true;
}

const sfxSiphon = Sound{
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

const siphonCost = 1; // housing
pub fn build_siphon(index: usize) bool {
    if (bank.stockpile.housing < siphonCost)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .spring)
        return false;

    tile.* = .siphon;
    bank.stockpile.housing -= 1;
    sfxSiphon.play();
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

const weaveryCost = 10; // mana
pub fn build_weavery(index: usize) bool {
    if (bank.stockpile.mana < weaveryCost)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .housing)
        return false;

    tile.* = .weavery;
    sfxHousingHigh.play();
    bank.stockpile.mana -= weaveryCost;
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
pub fn build_drill(index: usize) bool {
    if (bank.stockpile.housing < drillCost)
        return false;

    const tile = &map.tiles[index];
    if (tile.* != .empty)
        return false;

    tile.* = .drill;
    sfxHousingLow.play();
    bank.drillgen += 1;
    bank.stockpile.housing -= drillCost;
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
const teleportCost = 4;
pub fn teleport(index: usize) bool {
    if (bank.stockpile.mana < teleportCost)
        return false;
    _ = index;

    player.x = 82 << 2;
    player.y = 81 << 2;
    sfxTeleport.play();
    bank.stockpile.mana -= teleportCost;
    return true;
}

pub const Belt = struct {
    icon: *const [8]u8,
    func: fn (usize) bool,
    cost: u32,
    currency: Bank.CurrencyType,
    name: []const u8,
};

pub const array = [_]Belt{
    .{
        .icon = &icon_dig,
        .func = dig,
        .cost = 1,
        .currency = Bank.CurrencyType.Mana,
        .name = "dig",
    },
    .{
        .icon = &icon_house,
        .func = build_housing,
        .cost = housingCost,
        .currency = Bank.CurrencyType.Amber,
        .name = "workshop",
    },
    .{
        .icon = &Caveart.Spring,
        .func = build_siphon,
        .cost = siphonCost,
        .currency = Bank.CurrencyType.Housing,
        .name = "spring",
    },
    .{
        .icon = &icon_weavery,
        .func = build_weavery,
        .cost = weaveryCost,
        .currency = Bank.CurrencyType.Mana,
        .name = "weavery",
    },
    .{
        .icon = &icon_drill,
        .func = build_drill,
        .cost = drillCost,
        .currency = Bank.CurrencyType.Housing,
        .name = "drill",
    },
    .{
        .icon = &icon_teleport,
        .func = teleport,
        .cost = teleportCost,
        .currency = Bank.CurrencyType.Mana,
        .name = "teleport",
    },
};
