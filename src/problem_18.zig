const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Grid = [20][20][20]u8;

const Coord = struct {
    x: usize = 0,
    y: usize = 0,
    z: usize = 0,
};

const Dims = Coord;

fn createGrid(path: []const u8, dims: *Dims) anyerror!Grid {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var grid = std.mem.zeroes(Grid);

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var vals = std.mem.tokenize(u8, line, ",");
        const x = try std.fmt.parseInt(u8, vals.next().?, 10);
        const y = try std.fmt.parseInt(u8, vals.next().?, 10);
        const z = try std.fmt.parseInt(u8, vals.next().?, 10);
        dims.x = std.math.max(dims.x, x);
        dims.y = std.math.max(dims.y, y);
        dims.z = std.math.max(dims.z, z);
        grid[x][y][z] = 1;
    }

    dims.x += 1;
    dims.y += 1;
    dims.z += 1;

    return grid;
}

fn countExposedSides(grid: Grid, dims: Dims, c: Coord) usize {
    var sides: usize = 0;

    if (c.x == 0 or grid[c.x - 1][c.y][c.z] == 0) {
        sides += 1;
    }
    if (c.x == (dims.x - 1) or grid[c.x + 1][c.y][c.z] == 0) {
        sides += 1;
    }

    if (c.y == 0 or grid[c.x][c.y - 1][c.z] == 0) {
        sides += 1;
    }
    if (c.y == (dims.y - 1) or grid[c.x][c.y + 1][c.z] == 0) {
        sides += 1;
    }

    if (c.z == 0 or grid[c.x][c.y][c.z - 1] == 0) {
        sides += 1;
    }
    if (c.z == (dims.z - 1) or grid[c.x][c.y][c.z + 1] == 0) {
        sides += 1;
    }

    return sides;
}

fn solve(path: []const u8) anyerror!usize {
    var dims = Dims{};
    var grid = try createGrid(path, &dims);

    var sa: usize = 0;

    var x: usize = 0;
    while (x < dims.x) : (x += 1) {
        var y: usize = 0;
        while (y < dims.y) : (y += 1) {
            var z: usize = 0;
            while (z < dims.z) : (z += 1) {
                if (grid[x][y][z] == 1) {
                    const c = Coord{ .x = x, .y = y, .z = z };
                    sa += countExposedSides(grid, dims, c);
                }
            }
        }
    }

    return sa;
}

fn example1() anyerror!usize {
    return solve("problems/example_18.txt");
}

fn part1() anyerror!usize {
    return solve("problems/problem_18.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 64), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 3498), ans);
}
