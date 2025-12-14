const w4 = @import("wasm4.zig");
const std = @import("std");

const Layer = @import("Layer.zig");
const map: *Layer = &Layer.map;
const LayerProgress = @import("LayerProgress.zig");
const Bank = @import("Bank.zig");
const bank: *Bank = &Bank.bank;

var savebuffer: [6 + 140]u32 = undefined;
const saveSize = @sizeOf(@TypeOf(savebuffer));
comptime {
    if (saveSize > 1024) {
        @compileError("save buffer too large!");
    }
}

pub fn write_save() void {
    savebuffer[0] = bank.stockpile.crystal;
    savebuffer[1] = bank.stockpile.gem;
    savebuffer[2] = bank.stockpile.worker;
    savebuffer[3] = bank.stockpile.drill;
    savebuffer[4] = bank.drillgen;
    savebuffer[5] = LayerProgress.get_current();

    var mindex: usize = 0;
    while (mindex < map.tiles.len / 4) {
        // evil lol, mild compression
        const f: [*]u32 = @ptrFromInt(@intFromPtr(&map.tiles));
        savebuffer[mindex + 6] = f[mindex];

        mindex += 1;
    }

    _ = w4.diskw(std.mem.asBytes(&savebuffer), saveSize);
}

pub fn read_save() bool {
    const readCount = w4.diskr(std.mem.asBytes(&savebuffer), saveSize);
    if (readCount != saveSize) {
        return false;
    }

    bank.stockpile.crystal = savebuffer[0];
    bank.stockpile.gem = savebuffer[1];
    bank.stockpile.worker = savebuffer[2];
    bank.stockpile.drill = savebuffer[3];
    bank.drillgen = savebuffer[4];
    var rng = std.Random.DefaultPrng.init(savebuffer[0] + savebuffer[1] + savebuffer[2] + savebuffer[4]);

    LayerProgress.set_layer(@truncate(savebuffer[5]), rng.random());

    var sindex: usize = 6;
    var mindex: usize = 0;
    while (mindex < map.tiles.len) {
        const buf = std.mem.asBytes(&savebuffer[sindex]);
        for (buf, 0..) |tile, n| {
            map.tiles[mindex + n] = @enumFromInt(tile);
        }

        sindex += 1;
        mindex += 4;
    }
    return true;
}
