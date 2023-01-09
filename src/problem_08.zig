const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn createGrid(path: []const u8, nrows: *usize, ncols: *usize) ![99][99]i32 {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var grid = std.mem.zeroes([99][99]i32);
    nrows.* = std.mem.count(u8, buf, "\n");
    ncols.* = std.mem.indexOfPos(u8, buf, 0, "\n").?;

    var row: usize = 0;
    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var col: usize = 0;
        for (line) |char| {
            const height = char - '0';
            std.debug.assert(col < ncols.* and row < nrows.*);
            grid[row][col] = height;
            col += 1;
        }
        row += 1;
    }

    return grid;
}

fn solve1(path: []const u8) !usize {
    var nrows: usize = 0;
    var ncols: usize = 0;
    const grid = try createGrid(path, &nrows, &ncols);

    var cnt: usize = 2 * nrows + 2 * (ncols - 2);
    var row: usize = 1;
    while (row < nrows - 1) : (row += 1) {
        var col: usize = 1;
        while (col < ncols - 1) : (col += 1) {
            const height = grid[row][col];
            // walk north
            var other_row = row - 1;
            var visible = true;
            while (true) : (other_row -= 1) {
                const other_height = grid[other_row][col];
                if (other_height >= height) {
                    visible = false;
                    break;
                }
                if (other_row == 0) {
                    break;
                }
            }
            if (visible) {
                cnt += 1;
                continue;
            }
            // walk south
            other_row = row + 1;
            visible = true;
            while (true) : (other_row += 1) {
                const other_height = grid[other_row][col];
                if (other_height >= height) {
                    visible = false;
                    break;
                }
                if (other_row == nrows - 1) {
                    break;
                }
            }
            if (visible) {
                cnt += 1;
                continue;
            }
            // walk west
            var other_col = col - 1;
            visible = true;
            while (true) : (other_col -= 1) {
                const other_height = grid[row][other_col];
                if (other_height >= height) {
                    visible = false;
                    break;
                }
                if (other_col == 0) {
                    break;
                }
            }
            if (visible) {
                cnt += 1;
                continue;
            }
            // walk east
            other_col = col + 1;
            visible = true;
            while (true) : (other_col += 1) {
                const other_height = grid[row][other_col];
                if (other_height >= height) {
                    visible = false;
                    break;
                }
                if (other_col == ncols - 1) {
                    break;
                }
            }
            if (visible) {
                cnt += 1;
                continue;
            }
        }
    }

    return cnt;
}

fn solve2(path: []const u8) !usize {
    var nrows: usize = 0;
    var ncols: usize = 0;
    const grid = try createGrid(path, &nrows, &ncols);

    var max_score: usize = 0;
    var row: usize = 1;
    while (row < nrows - 1) : (row += 1) {
        var col: usize = 1;
        while (col < ncols - 1) : (col += 1) {
            const height = grid[row][col];
            var score: usize = 1;
            // walk north
            var other_row = row - 1;
            var ntrees: usize = 0;
            while (true) : (other_row -= 1) {
                ntrees += 1;
                const other_height = grid[other_row][col];
                if (other_height >= height) {
                    break;
                }
                if (other_row == 0) {
                    break;
                }
            }
            score *= ntrees;
            // walk south
            other_row = row + 1;
            ntrees = 0;
            while (true) : (other_row += 1) {
                ntrees += 1;
                const other_height = grid[other_row][col];
                if (other_height >= height) {
                    break;
                }
                if (other_row == nrows - 1) {
                    break;
                }
            }
            score *= ntrees;
            // walk west
            var other_col = col - 1;
            ntrees = 0;
            while (true) : (other_col -= 1) {
                ntrees += 1;
                const other_height = grid[row][other_col];
                if (other_height >= height) {
                    break;
                }
                if (other_col == 0) {
                    break;
                }
            }
            score *= ntrees;
            // walk east
            other_col = col + 1;
            ntrees = 0;
            while (true) : (other_col += 1) {
                ntrees += 1;
                const other_height = grid[row][other_col];
                if (other_height >= height) {
                    break;
                }
                if (other_col == ncols - 1) {
                    break;
                }
            }
            score *= ntrees;

            max_score = std.math.max(max_score, score);
        }
    }

    return max_score;
}

fn example1() !usize {
    return solve1("problems/example_08.txt");
}

fn example2() !usize {
    return solve2("problems/example_08.txt");
}

fn part1() !usize {
    return solve1("problems/problem_08.txt");
}

fn part2() !usize {
    return solve2("problems/problem_08.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 21), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 8), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 1825), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 235200), ans);
}
