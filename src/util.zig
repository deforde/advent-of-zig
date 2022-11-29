const std = @import("std");

pub fn readFileIntoBuf(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var realpath = try std.fs.realpathAlloc(allocator, path);
    var file = try std.fs.openFileAbsolute(realpath, .{});
    return file.readToEndAlloc(allocator, 10 * 1024 * 1024);
}
