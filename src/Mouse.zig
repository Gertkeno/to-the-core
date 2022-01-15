const Buttons = packed struct {
    left: bool = false,
    right: bool = false,
    middle: bool = false,
    _: u5 = 0,
};

const Self = @This();

previous: u8,

pressed: Buttons,
held: Buttons,
released: Buttons,

pub fn update(self: *Self, newmouse: u8) void {
    self.previous = @bitCast(u8, self.held);
    self.held = @bitCast(Buttons, newmouse);

    self.pressed = @bitCast(Buttons, newmouse & newmouse ^ self.previous);
    self.released = @bitCast(Buttons, self.previous & newmouse ^ self.previous);
}
