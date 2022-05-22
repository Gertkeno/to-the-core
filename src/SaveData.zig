const w4 = @import("wasm4.zig");
const std = @import("std").mem;

const Layer = @import("Layer.zig");
const LayerProgress = @import("LayerProgress.zig");
const Bank = @import("Bank.zig");
extern var bank: Bank;
extern var map: Layer;

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
        const f = @intToPtr([*]u32, @ptrToInt(&map.tiles));
        savebuffer[mindex + 6] = f[mindex];

        mindex += 1;
    }

    _ = w4.diskw(std.asBytes(&savebuffer), saveSize);
}

pub fn read_save() bool {
    const readCount = w4.diskr(std.asBytes(&savebuffer), saveSize);
    if (readCount != saveSize) {
        return false;
    }

    bank.stockpile.crystal = savebuffer[0];
    bank.stockpile.gem = savebuffer[1];
    bank.stockpile.worker = savebuffer[2];
    bank.stockpile.drill = savebuffer[3];
    bank.drillgen = savebuffer[4];
    LayerProgress.set_layer(@truncate(u8, savebuffer[5]));

    var sindex: usize = 6;
    var mindex: usize = 0;
    while (mindex < map.tiles.len) {
        const buf = std.asBytes(&savebuffer[sindex]);
        for (buf) |tile, n| {
            map.tiles[mindex + n] = @intToEnum(Layer.Tiles, tile);
        }

        sindex += 1;
        mindex += 4;
    }
    return true;
}
