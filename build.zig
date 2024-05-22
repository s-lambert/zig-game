const std = @import("std");
const jok = @import("jok");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = jok.createGame(
        b,
        "mygame",
        "src/main.zig",
        target,
        optimize,
        .{},
    );
    const install_cmd = b.addInstallArtifact(exe, .{});

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(&install_cmd.step);

    const run_step = b.step("run", "Run game");
    run_step.dependOn(&run_cmd.step);

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raylib_math = raylib_dep.module("raylib-math"); // raymath module
    const rlgl = raylib_dep.module("rlgl"); // rlgl module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    const raylib_exe = b.addExecutable(.{
        .name = "raylib-game",
        .root_source_file = b.path("src/tile_editor.zig"),
        .optimize = optimize,
        .target = target,
    });

    raylib_exe.linkLibrary(raylib_artifact);
    raylib_exe.root_module.addImport("raylib", raylib);
    raylib_exe.root_module.addImport("raylib-math", raylib_math);
    raylib_exe.root_module.addImport("rlgl", rlgl);

    const run_editor_cmd = b.addRunArtifact(raylib_exe);
    const run_editor_step = b.step("editor", "Run tile editor");

    run_editor_step.dependOn(&run_editor_cmd.step);
}
