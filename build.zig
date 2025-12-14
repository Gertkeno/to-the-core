const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});

    const module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        }),
    });

    module.export_symbol_names = &[_][]const u8{ "start", "update" };

    const exe = b.addExecutable(.{
        .name = "cart",
        .root_module = module,
        .version = try std.SemanticVersion.parse("4.0.0"),
    });

    exe.entry = .disabled;
    exe.import_memory = true;
    exe.initial_memory = 65536;
    exe.max_memory = 65536;
    exe.stack_size = 14752;

    b.installArtifact(exe);
}
