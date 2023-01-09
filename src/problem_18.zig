const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Grid = [20][20][20]u8;

const Coord = struct {
    x: usize = 0,
    y: usize = 0,
    z: usize = 0,
};

const Dims = Coord;

fn createGrid(path: []const u8, dims: *Dims) !Grid {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

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

fn countExposedSides1(grid: Grid, dims: Dims, c: Coord) usize {
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

fn countExposedSides2(grid: Grid, dims: Dims, c: Coord) usize {
    var sides: usize = 0;

    if (c.x == 0 or grid[c.x - 1][c.y][c.z] == 2) {
        sides += 1;
    }
    if (c.x == (dims.x - 1) or grid[c.x + 1][c.y][c.z] == 2) {
        sides += 1;
    }

    if (c.y == 0 or grid[c.x][c.y - 1][c.z] == 2) {
        sides += 1;
    }
    if (c.y == (dims.y - 1) or grid[c.x][c.y + 1][c.z] == 2) {
        sides += 1;
    }

    if (c.z == 0 or grid[c.x][c.y][c.z - 1] == 2) {
        sides += 1;
    }
    if (c.z == (dims.z - 1) or grid[c.x][c.y][c.z + 1] == 2) {
        sides += 1;
    }

    return sides;
}

fn isExposed(grid: Grid, dims: Dims, c: Coord) bool {
    if (c.x == 0 or grid[c.x - 1][c.y][c.z] == 2) {
        return true;
    }
    if (c.x == (dims.x - 1) or grid[c.x + 1][c.y][c.z] == 2) {
        return true;
    }

    if (c.y == 0 or grid[c.x][c.y - 1][c.z] == 2) {
        return true;
    }
    if (c.y == (dims.y - 1) or grid[c.x][c.y + 1][c.z] == 2) {
        return true;
    }

    if (c.z == 0 or grid[c.x][c.y][c.z - 1] == 2) {
        return true;
    }
    if (c.z == (dims.z - 1) or grid[c.x][c.y][c.z + 1] == 2) {
        return true;
    }

    return false;
}

fn floodFill(grid: *Grid, dims: Dims) void {
    var change_detected = true;
    while (change_detected) {
        change_detected = false;
        var x: usize = 0;
        while (x < dims.x) : (x += 1) {
            var y: usize = 0;
            while (y < dims.y) : (y += 1) {
                var z: usize = 0;
                while (z < dims.z) : (z += 1) {
                    if (grid[x][y][z] == 0) {
                        const c = Coord{ .x = x, .y = y, .z = z };
                        if (isExposed(grid.*, dims, c)) {
                            grid[x][y][z] = 2;
                            change_detected = true;
                        }
                    }
                }
            }
        }
    }
}

fn solve1(path: []const u8) !usize {
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
                    sa += countExposedSides1(grid, dims, c);
                }
            }
        }
    }

    return sa;
}

fn solve2(path: []const u8) !usize {
    var dims = Dims{};
    var grid = try createGrid(path, &dims);
    floodFill(&grid, dims);

    var sa: usize = 0;

    var x: usize = 0;
    while (x < dims.x) : (x += 1) {
        var y: usize = 0;
        while (y < dims.y) : (y += 1) {
            var z: usize = 0;
            while (z < dims.z) : (z += 1) {
                if (grid[x][y][z] == 1) {
                    const c = Coord{ .x = x, .y = y, .z = z };
                    sa += countExposedSides2(grid, dims, c);
                }
            }
        }
    }

    return sa;
}

fn example1() !usize {
    return solve1("problems/example_18.txt");
}

fn example2() !usize {
    return solve2("problems/example_18.txt");
}

fn part1() !usize {
    return solve1("problems/problem_18.txt");
}

fn part2() !usize {
    return solve2("problems/problem_18.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 64), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 58), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 3498), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 2008), ans);
}
