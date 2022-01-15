const Sprite = @import("Sprite.zig");
const w4 = @import("wasm4");

const Self = @This();

pub const Tiles = enum(u4) {
    empty,
    stone,
    spring,
};

tiles: [380]Tiles = undefined,

fn get_surrounding_tile(self: Self, index: usize, tile: Tiles) Sprite.Faces {
    var faces: Sprite.Faces = undefined;
    const x = index % 20;
    const y = index / 20;

    if (y == 0) {
        faces.up = true;
    } else {
        faces.up = self.tiles[(y - 1) * 20 + x] == tile;
    }

    if (y == 18) {
        faces.down = true;
    } else {
        faces.down = self.tiles[(y + 1) * 20 + x] == tile;
    }

    if (x == 0) {
        faces.left = true;
    } else {
        faces.left = self.tiles[y * 20 + x - 1] == tile;
    }

    if (x == 19) {
        faces.right = true;
    } else {
        faces.right = self.tiles[y * 20 + x + 1] == tile;
    }

    return faces;
}

pub fn draw(self: Self) void {
    for (self.tiles) |tile, n| {
        switch (tile) {
            .stone => {
                const x: i32 = @intCast(i32, n % 20 * 8);
                const y: i32 = @intCast(i32, n / 20 * 8) + 8;
                Sprite.blitstone(self.get_surrounding_tile(n, .stone), x, y);
            },
            else => {},
        }
    }
}
