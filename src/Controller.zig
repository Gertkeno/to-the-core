const Gamepad = packed struct {
    x: bool = false,
    y: bool = false,
    _: u2 = 0,
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,
};

const Self = @This();

previous: u8 = 0,

pressed: Gamepad = .{},
held: Gamepad = .{},
released: Gamepad = .{},

pub fn update(self: *Self, newgamepad: u8) void {
    self.previous = @bitCast(u8, self.held);
    self.held = @bitCast(Gamepad, newgamepad);

    self.pressed = @bitCast(Gamepad, newgamepad & newgamepad ^ self.previous);
    self.released = @bitCast(Gamepad, self.previous & newgamepad ^ self.previous);
}
