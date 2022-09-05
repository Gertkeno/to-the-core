const w4 = @import("wasm4.zig");

pub fn player() u2 {
    return @truncate(u2, w4.NETPLAY.* & 0b11);
}

pub fn enabled() bool {
    return w4.NETPLAY.* & 0b100 > 0;
}
