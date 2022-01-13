const std = @import("std");
export var ram: [2 * 2048]u8 = undefined;

pub var fba = std.heap.FixedBufferAllocator.init(&ram);
pub const allocator = fba.allocator();
