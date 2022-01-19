const Cave = @import("Caveart.zig");
const Build = @import("Buildart.zig");
const std = @import("std");
const w4 = @import("wasm4.zig");

const Self = @This();

pub const Tiles = enum(u8) {
    // cave //
    empty,
    stone,
    spring,
    deposit,
    // built //
    siphon,
    housing,
};

tiles: [380]Tiles = undefined,

fn is_stone(tile: Tiles) bool {
    return switch (tile) {
        .stone, .spring, .deposit => true,
        else => false,
    };
}

fn is_empty(tile: Tiles) bool {
    return switch (tile) {
        .empty => true,
        else => false,
    };
}

fn get_surrounding_tile(self: Self, index: usize, func: fn (Tiles) bool) Cave.Faces {
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

fn draw_tile(self: Self, index: usize) void {
    const tile = self.tiles[index];
    const x: i32 = @intCast(i32, index % 20 * 8);
    const y: i32 = @intCast(i32, index / 20 * 8) + 8;
    switch (tile) {
        .stone, .spring, .deposit => {
            w4.DRAW_COLORS.* = 0x43;
            const stones = self.get_surrounding_tile(index, is_stone);
            Cave.blitstone(stones, x, y);
        },
        .empty => {
            w4.DRAW_COLORS.* = 0x21;
            Cave.blitempty(self.get_surrounding_tile(index, is_empty), x, y);
        },
        .siphon => {
            w4.DRAW_COLORS.* = 0x12;
            w4.blit(&Build.Siphon, x, y, 8, 8, 0);
        },
        .housing => {
            w4.DRAW_COLORS.* = 0x12;
            w4.blit(&Build.Lair, x, y, 8, 8, 0);
        },
    }

    // extra cave draws
    switch (tile) {
        .spring => {
            w4.DRAW_COLORS.* = 0x10;
            w4.blit(&Cave.Spring, x, y, 8, 8, 0);
        },
        .deposit => {
            w4.DRAW_COLORS.* = 0x20;
            const flippy = (index % 31) & 0b1110;
            w4.blit(&Cave.Deposit, x, y, 8, 8, flippy);
        },
        else => {},
    }
}

pub fn draw_full(self: Self) void {
    for (self.tiles) |_, n| {
        self.draw_tile(n);
    }
}

pub fn draw_at(self: Self, x: i32, y: i32) void {
    const index = @intCast(usize, x + y * 20);
    const surrounding = [_]i32{ -21, -20, -19, -1, 1, 19, 20, 21 };

    for (surrounding) |diff| {
        if (-diff < index and index + diff < self.tiles.len) {
            const dindex = @intCast(usize, index + diff);
            self.draw_tile(dindex);
        }
    }
}

// initializeation //

pub fn init_blank(self: *Self) void {
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
            const dindex = @intCast(usize, index + diff);
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
            const index = @intCast(usize, x + y * 20);
            const neighbours = alive_neighbours(oldmap, x, y);

            if (oldmap[index]) {
                newmap[index] = neighbours > deathNeighbors;
            } else {
                newmap[index] = neighbours > birthNeighbors;
            }
        }
    }
}

pub fn init_cave(self: *Self, layer: i32, rng: std.rand.Random) void {
    var caveOldBuffer: [380]bool = undefined;
    var caveNewBuffer: [380]bool = undefined;

    for (caveOldBuffer) |*b| {
        b.* = rng.boolean();
    }

    var simsteps: usize = simulationSteps;
    while (simsteps > 0) : (simsteps -= 1) {
        simulate_cave(&caveOldBuffer, &caveNewBuffer);
        std.mem.copy(bool, &caveOldBuffer, &caveNewBuffer);
    }

    for (self.tiles) |*tile, n| {
        tile.* = if (caveOldBuffer[n]) .stone else .empty;
    }

    var springs = std.math.max(5 - (layer >> 3), 1);
    while (springs > 0) : (springs -= 1) {
        const index = rng.uintAtMost(u32, 379);
        self.tiles[index] = .spring;
    }

    const startsquare = [_]usize{ 189, 190, 170, 210 };
    for (startsquare) |index| {
        self.tiles[index] = .empty;
    }

    for (caveOldBuffer) |*b| {
        b.* = rng.boolean();
    }

    simulate_cave(&caveOldBuffer, &caveNewBuffer);
    std.mem.copy(bool, &caveOldBuffer, &caveNewBuffer);
    simulate_cave(&caveOldBuffer, &caveNewBuffer);

    for (self.tiles) |*tile, n| {
        if (!caveNewBuffer[n] and tile.* == .stone) {
            tile.* = .deposit;
        }
    }
}

pub fn get_tile(self: *Self, x: i32, y: i32) *Tiles {
    if (x < 0 or y < 0 or x > 20 or y > 19) {
        unreachable;
    }

    const index = @intCast(usize, x + y * 20);
    return &self.tiles[index];
}

pub fn set_tile(self: *Self, x: i32, y: i32, tile: Tiles) void {
    const index = @intCast(usize, x + y * 20);
    self.tiles[index] = tile;
}

pub fn walkable(self: Self, x: i32, y: i32) bool {
    const index = @intCast(usize, x + y * 20);
    const tile = self.tiles[index];
    return switch (tile) {
        .empty, .siphon, .housing => true,
        .stone, .spring, .deposit => false,
    };
}
