const w4 = @import("wasm4.zig");
const std = @import("std").mem;
const LayerProgress = @import("LayerProgress.zig");
const Bank = @import("Bank.zig");
extern var bank: Bank;

var savebuffer: [6]u32 = undefined;
const saveSize = @sizeOf(@TypeOf(savebuffer));
pub fn write_save() void {
    savebuffer[0] = bank.stockpile.mana;
    savebuffer[1] = bank.stockpile.amber;
    savebuffer[2] = bank.stockpile.housing;
    savebuffer[3] = bank.stockpile.drill;
    savebuffer[4] = bank.drillgen;
    savebuffer[5] = LayerProgress.get_current();

    _ = w4.diskw(std.asBytes(&savebuffer), saveSize);
}

pub fn read_save() bool {
    const readCount = w4.diskr(std.asBytes(&savebuffer), saveSize);
    if (readCount != saveSize) {
        return false;
    }

    bank.stockpile.mana = savebuffer[0];
    bank.stockpile.amber = savebuffer[1];
    bank.stockpile.housing = savebuffer[2];
    bank.stockpile.drill = savebuffer[3];
    bank.drillgen = savebuffer[4];
    LayerProgress.set_layer(@truncate(u8, savebuffer[5]));
    return true;
}
