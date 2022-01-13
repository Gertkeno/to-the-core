inline fn btest(a: u8, b: u8) bool {
    return a & b == b;
}

const Self = @This();

previous: u8 = 0,

pressed: u8 = 0,
current: u8 = 0,
released: u8 = 0,

pub fn update(self: *Self, newgamepad: u8) void {
    self.previous = self.current;
    self.current = newgamepad;

    self.pressed = self.current & (self.current ^ self.previous);
    self.released = self.previous & (self.current ^ self.previous);
}

pub fn is_pressed(self: Self, key: u8) bool {
    return btest(self.pressed, key);
}

pub fn is_held(self: Self, key: u8) bool {
    return btest(self.current, key);
}

pub fn is_released(self: Self, key: u8) bool {
    return btest(self.released, key);
}
