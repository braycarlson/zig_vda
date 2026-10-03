const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vd_module = b.addModule("vd", .{
        .root_source_file = b.path("src/vd.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "zig-vd",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/vd.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(lib);

    const examples = [_]struct { name: []const u8, path: []const u8 }{
        .{ .name = "enumerate_desktops", .path = "examples/enumerate_desktops.zig" },
        .{ .name = "switch_desktop", .path = "examples/switch_desktop.zig" },
        .{ .name = "create_remove_desktop", .path = "examples/create_remove_desktop.zig" },
        .{ .name = "move_window", .path = "examples/move_window.zig" },
        .{ .name = "pin_window", .path = "examples/pin_window.zig" },
        .{ .name = "pin_app", .path = "examples/pin_app.zig" },
        .{ .name = "rename_desktop", .path = "examples/rename_desktop.zig" },
        .{ .name = "error_handling", .path = "examples/error_handling.zig" },
        .{ .name = "desktop_notifications", .path = "examples/desktop_notifications.zig" },
        .{ .name = "test_all", .path = "examples/test_all.zig" },
    };

    for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(example.path),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "vd", .module = vd_module },
                },
            }),
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        run_cmd.addPassthruArgs();

        const run_step = b.step(example.name, b.fmt("Run the {s} example", .{example.name}));
        run_step.dependOn(&run_cmd.step);
    }

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/vd.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
