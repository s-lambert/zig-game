const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    const editor_exe = b.addExecutable(.{
        .name = "raylib-editor",
        .root_source_file = b.path("src/editor_main.zig"),
        .optimize = optimize,
        .target = target,
    });

    editor_exe.linkLibrary(raylib_artifact);
    editor_exe.root_module.addImport("raylib", raylib);
    editor_exe.root_module.addImport("raygui", raygui);

    const run_editor_cmd = b.addRunArtifact(editor_exe);
    const run_editor_step = b.step("editor", "Run tile editor");

    run_editor_step.dependOn(&run_editor_cmd.step);

    const game_exe = b.addExecutable(.{
        .name = "raylib-game",
        .root_source_file = b.path("src/game_main.zig"),
        .optimize = optimize,
        .target = target,
    });

    game_exe.linkLibrary(raylib_artifact);
    game_exe.root_module.addImport("raylib", raylib);

    const run_game_cmd = b.addRunArtifact(game_exe);
    const run_game_step = b.step("game", "Run game");

    run_game_step.dependOn(&run_game_cmd.step);

    const game_check = b.addExecutable(.{
        .name = "raylib-game",
        .root_source_file = b.path("src/game_main.zig"),
        .target = target,
        .optimize = optimize,
    });

    game_check.linkLibrary(raylib_artifact);
    game_check.root_module.addImport("raylib", raylib);

    const editor_check = b.addExecutable(.{
        .name = "raylib-editor",
        .root_source_file = b.path("src/editor_main.zig"),
        .optimize = optimize,
        .target = target,
    });

    editor_check.linkLibrary(raylib_artifact);
    editor_check.root_module.addImport("raylib", raylib);
    editor_check.root_module.addImport("raygui", raygui);

    const check = b.step("check", "Check if raylib-game compiles");
    check.dependOn(&game_check.step);
    check.dependOn(&editor_check.step);

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });
    const hello = b.addExecutable(.{
        .name = "hello",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/sokol_main.zig"),
    });
    hello.root_module.addImport("sokol", dep_sokol.module("sokol"));
    b.installArtifact(hello);
    const run = b.addRunArtifact(hello);
    b.step("sokol", "Run hello").dependOn(&run.step);
}
