const std = @import("std");
const w4 = @import("wasm4.zig");

const Cave = @import("Caveart.zig");
const Build = @import("Buildart.zig");
const Sound = @import("Sound.zig");
const Pickup = @import("Pickup.zig");

const Self = @This();
pub var map = Self{};

pub const Tiles = enum(u8) {
    // cave //
    empty,
    stone,
    diamonds,
    gems,
    // built //
    spring,
    workshop,
    weavery,
    drill,
};

const TILE_MAX = 19 * 20;
tiles: [TILE_MAX]Tiles = undefined,
dirty_flags: [19]u32 = [_]u32{0xffffffff} ** 19,

frameCount: usize = 0,
pickups: [90]Pickup = undefined,
active: usize = 0,
rng: std.Random = undefined,

// tile properties //
fn is_raised(tile: Tiles) bool {
    return switch (tile) {
        .stone,
        .diamonds,
        .gems,
        .spring,
        => true,
        .empty,
        .drill,
        .workshop,
        .weavery,
        => false,
    };
}

fn is_empty(tile: Tiles) bool {
    return switch (tile) {
        .empty => true,
        else => false,
    };
}

pub fn walkable(self: Self, x: i32, y: i32) bool {
    const index: usize = @intCast(x + y * 20);
    const tile = self.tiles[index];

    return tile == .empty;
}

fn get_surrounding_tile(self: Self, index: usize, func: *const fn (Tiles) bool) Cave.Faces {
    var faces: Cave.Faces = undefined;
    const x = index % 20;
    const y = index / 20;

    if (y == 0) {
        faces.up = true;
    } else {
        faces.up = func(self.tiles[index - 20]);
    }

    if (y == 18) {
        faces.down = true;
    } else {
        faces.down = func(self.tiles[index + 20]);
    }

    if (x == 0) {
        faces.left = true;
    } else {
        faces.left = func(self.tiles[index - 1]);
    }

    if (x == 19) {
        faces.right = true;
    } else {
        faces.right = func(self.tiles[index + 1]);
    }

    return faces;
}

// DRAW //
inline fn draw_tile(self: Self, index: usize) void {
    const tile = self.tiles[index];
    const x: i32 = @intCast(index % 20 * 8);
    const y = @as(i32, @intCast(index / 20 * 8)) + 8;
    switch (tile) {
        .stone, .diamonds, .gems, .spring => {
            w4.DRAW_COLORS.* = 0x43;
            const stones = self.get_surrounding_tile(index, is_raised);
            Cave.blitstone(stones, x, y);
        },
        .empty => {
            w4.DRAW_COLORS.* = 0x21;
            const empties = self.get_surrounding_tile(index, is_empty);
            Cave.blitempty(empties, x, y);
        },
        .workshop => {
            w4.DRAW_COLORS.* = 0x1234;
            w4.blit(&Build.workshop, x, y, 8, 8, 1);
        },
        .weavery => {
            w4.DRAW_COLORS.* = 0x1234;
            w4.blit(&Build.weavery, x, y, 8, 8, 1);
        },
        .drill => {
            w4.DRAW_COLORS.* = 0x1234;
            w4.blit(&Build.drill, x, y, 8, 8, 1);
        },
    }

    // extra cave draws
    switch (tile) {
        .diamonds => {
            w4.DRAW_COLORS.* = 0x10;
            w4.blit(&Cave.diamonds, x, y, 8, 8, 0);
        },
        .gems => {
            w4.DRAW_COLORS.* = 0x20;
            const flippy = (index % 31) & 0b1110;
            w4.blit(&Cave.gems, x, y, 8, 8, flippy);
        },
        .spring => {
            w4.DRAW_COLORS.* = 0x20;
            w4.blit(&Build.spring, x, y, 8, 8, 0);
        },
        else => {},
    }
}

pub fn draw_full(self: *Self) void {
    for (self.tiles, 0..) |_, n| {
        const x: u5 = @intCast(n % 20);
        const y = n / 20;

        const dirty: bool = (self.dirty_flags[y] & (@as(u32, 0b1) << x)) != 0;
        if (dirty) {
            // expensive stone/empty bitwise ors ~4 times per 20*19 tiles
            self.draw_tile(n);
        }
    }

    @memset(&self.dirty_flags, 0);
}

pub fn set_dirty(self: *Self, x: u5, y: u5) void {
    if (y < 18)
        self.dirty_flags[y + 1] |= @as(u32, 0b111) << @max(x, 1) - 1;
    if (y != 0)
        self.dirty_flags[y - 1] |= @as(u32, 0b111) << @max(x, 1) - 1;
    if (y < 19)
        self.dirty_flags[y + 0] |= @as(u32, 0b111) << @max(x, 1) - 1;
}

pub fn set_dirty_all(self: *Self) void {
    @memset(&self.dirty_flags, 0xFFFFFFFF);
}

// INITIALIZEATION //
pub fn init_blank(self: *Self) void {
    self.active = 0;
    for (self.tiles) |*tile| {
        tile.* = .stone;
    }

    const startsquare = [_]usize{ 188, 189, 190, 209, 210, 211 };
    for (startsquare) |index| {
        self.tiles[index] = .empty;
    }
}

// cellular cave initialize //
const deathNeighbors = 2;
const birthNeighbors = 3;
const simulationSteps = 2;

fn alive_neighbours(bitset: []const bool, x: i32, y: i32) u8 {
    var alive: u8 = 0;
    const surrounding = [_]i8{ -21, -20, -19, -1, 1, 19, 20, 21 };

    const index = x + y * 20;
    for (surrounding) |diff| {
        if (index + diff > 0 and index + diff < bitset.len) {
            const dindex: usize = @intCast(index + diff);
            if (bitset[dindex]) {
                alive += 1;
            }
        } else {
            alive += 1;
        }
    }

    return alive;
}

fn simulate_cave(oldmap: []const bool, newmap: []bool) void {
    var y: i32 = 0;
    while (y < 19) : (y += 1) {
        var x: i32 = 0;
        while (x < 20) : (x += 1) {
            const index: usize = @intCast(x + y * 20);
            const neighbours = alive_neighbours(oldmap, x, y);

            if (oldmap[index]) {
                newmap[index] = neighbours > deathNeighbors;
            } else {
                newmap[index] = neighbours > birthNeighbors;
            }
        }
    }
}

pub fn init_cave(self: *Self, layer: i32, rng: std.Random) void {
    self.active = 0;
    self.rng = rng;
    var caveOldBuffer: [TILE_MAX]bool = undefined;
    var caveNewBuffer: [TILE_MAX]bool = undefined;

    for (&caveOldBuffer) |*b| {
        b.* = rng.boolean();
    }

    var simsteps: usize = simulationSteps;
    while (simsteps > 0) : (simsteps -= 1) {
        simulate_cave(&caveOldBuffer, &caveNewBuffer);
        @memcpy(&caveOldBuffer, &caveNewBuffer);
    }

    for (&self.tiles, 0..) |*tile, n| {
        tile.* = if (caveOldBuffer[n]) .stone else .empty;
    }

    var diamonds = @max(5 - (layer >> 1), 1);
    while (diamonds > 0) : (diamonds -= 1) {
        const index = rng.uintAtMost(u32, 379);
        self.tiles[index] = .diamonds;
    }

    const startsquare = [_]usize{ 189, 190, 170, 210 };
    for (startsquare) |index| {
        self.tiles[index] = .empty;
    }

    for (&caveOldBuffer) |*b| {
        b.* = rng.boolean();
    }

    simulate_cave(&caveOldBuffer, &caveNewBuffer);
    @memcpy(&caveOldBuffer, &caveNewBuffer);
    simulate_cave(&caveOldBuffer, &caveNewBuffer);

    for (&self.tiles, 0..) |*tile, n| {
        if (!caveNewBuffer[n] and tile.* == .stone) {
            tile.* = .gems;
        }
    }
    self.set_dirty_all();
}

// INDEXING //
pub fn get_tile(self: *Self, x: i32, y: i32) *Tiles {
    if (x < 0 or y < 0 or x > 20 or y > 19) {
        unreachable;
    }

    const index: usize = @intCast(x + y * 20);
    return &self.tiles[index];
}

pub fn set_tile(self: *Self, x: i32, y: i32, tile: Tiles) void {
    const index: usize = @intCast(x + y * 20);
    self.tiles[index] = tile;
}

// UPDATE/PICKUPS SPAWNING //
const Point = struct {
    x: i32,
    y: i32,
};

fn random_in_tile(index: usize, rng: std.Random) Point {
    const x: i32 = @intCast(index % 20);
    const y: i32 = @intCast(index / 20);

    return Point{
        .x = x * 8 + rng.uintAtMost(u8, 4),
        .y = y * 8 + rng.uintAtMost(u8, 4) + 8,
    };
}

fn random_adjacent_tile(index: usize, rng: std.Random) usize {
    const sindex: i32 = @intCast(index);
    const surrounding = [_]i8{ -20, -1, 1, 20 };
    const diff = surrounding[rng.uintLessThanBiased(u8, 4)];
    if (sindex + diff < 0 or sindex + diff > TILE_MAX) {
        for (surrounding) |ndiff| {
            if (sindex + ndiff > 0 and sindex + ndiff < TILE_MAX) {
                return @intCast(sindex + ndiff);
            }
        }
        unreachable;
    } else {
        return @intCast(sindex + diff);
    }
}

pub fn add_pickup(self: *Self, index: usize, currency: Bank.CurrencyType) void {
    const pos = random_in_tile(index, self.rng);
    const t: u16 = @truncate(self.frameCount);
    if (self.active < self.pickups.len) {
        self.pickups[self.active] = Pickup.init_xy(pos.x, pos.y, currency, t);
        self.active += 1;
    } else {
        const overwritei = self.rng.uintLessThanBiased(u8, self.pickups.len);
        self.pickups[overwritei] = Pickup.init_xy(pos.x, pos.y, currency, t);
        //w4.trace("pickups full");
    }
}

const weaveryInterval = 2193;
const springInterval = 837;
pub fn update(self: *Self) void {
    self.frameCount +%= 1;

    // always spawn a crystal in the center for saftey
    if (self.frameCount % springInterval == 0 and self.tiles[190] == .empty) {
        self.add_pickup(random_adjacent_tile(190, self.rng), .Crystal);
    }

    // spawn from various generating tiles
    for (self.tiles, 0..) |tile, n| {
        switch (tile) {
            .spring => {
                if ((n + self.frameCount) % springInterval != 0)
                    continue;

                self.add_pickup(random_adjacent_tile(n, self.rng), .Crystal);
            },
            .weavery => {
                if ((n * n + self.frameCount) % weaveryInterval != 0)
                    continue;
                self.add_pickup(random_adjacent_tile(n, self.rng), .Gem);
            },
            else => {},
        }
    }

    // re-draw everything periodically
    if ((self.frameCount & 0xFF) == 0) {
        self.set_dirty_all();
    }
}

pub fn draw_pickups(self: Self) void {
    const t: u16 = @truncate(self.frameCount);
    w4.DRAW_COLORS.* = 0x2430;
    for (self.pickups[0..self.active]) |pickup| {
        pickup.draw(t);
    }
}

const sfxPickup = Sound{
    .freq = .{
        .start = 900,
    },
    .channel = w4.TONE_MODE3,
};
const Bank = @import("Bank.zig");
const bank: *Bank = &Bank.bank;
pub fn check_pickups(self: *Self, charx: i32, chary: i32) ?Bank.CurrencyType {
    for (self.pickups[0..self.active], 0..) |pickup, n| {
        if (pickup.contact(charx, chary)) {
            sfxPickup.play();
            const c = pickup.currency;
            self.active -= 1;
            std.mem.swap(Pickup, &self.pickups[self.active], &self.pickups[n]);
            return c;
        }
    }

    if (bank.stockpile.drill >= 160 << Bank.DrillShift and chary <= 8) {
        return .None;
    }

    return null;
}
