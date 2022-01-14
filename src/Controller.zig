const gamepad = packed struct {
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

pressed: gamepad = .{},
held: gamepad = .{},
released: gamepad = .{},

pub fn update(self: *Self, newgamepad: u8) void {
    self.previous = @bitCast(u8, self.held);
    self.held = @bitCast(gamepad, newgamepad);

    self.pressed = @bitCast(gamepad, newgamepad & newgamepad ^ self.previous);
    self.released = @bitCast(gamepad, self.previous & newgamepad ^ self.previous);
}
