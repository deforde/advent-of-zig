const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;
const Allocator = @import("allocator.zig").Allocator;

const Grid = [41][181]u8;

const Coord = struct {
    x: usize = 0,
    y: usize = 0,
};

const PathTip = struct {
    pos: Coord = Coord{},
    len: usize = 0,
};

const Dir = enum { FWD, REV };

fn createGrid(allocator: std.mem.Allocator, path: []const u8, nrows: *usize, ncols: *usize, start: *Coord, end: *Coord) !Grid {
    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var grid = std.mem.zeroes(Grid);
    nrows.* = std.mem.count(u8, buf, "\n");
    ncols.* = std.mem.indexOfPos(u8, buf, 0, "\n").?;

    var row: usize = 0;
    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var col: usize = 0;
        for (line) |char| {
            var height: u8 = 0;
            switch (char) {
                'S' => {
                    start.* = Coord{ .x = row, .y = col };
                    height = 0;
                },
                'E' => {
                    end.* = Coord{ .x = row, .y = col };
                    height = 25;
                },
                else => {
                    height = char - 'a';
                },
            }
            std.debug.assert(col < ncols.* and row < nrows.*);
            grid[row][col] = height;
            col += 1;
        }
        row += 1;
    }

    return grid;
}

fn procMove(height: i32, other_pos: Coord, dir: Dir, grid: Grid, visited: Grid, moves: *std.ArrayList(Coord)) !void {
    const other_height = grid[other_pos.x][other_pos.y];
    const viable = switch (dir) {
        Dir.FWD => other_height <= height + 1,
        Dir.REV => height <= other_height + 1,
    };
    if (viable and visited[other_pos.x][other_pos.y] != 1) {
        try moves.*.append(other_pos);
    }
}

fn getViableMoves(allocator: std.mem.Allocator, grid: Grid, nrows: usize, ncols: usize, visited: Grid, pos: Coord, dir: Dir) !std.ArrayList(Coord) {
    var moves = std.ArrayList(Coord).init(allocator);
    const height = grid[pos.x][pos.y];

    const xmin = if (pos.x > 0) pos.x - 1 else 0;
    const xmax = std.math.min(pos.x + 1, nrows - 1);
    const ymin = if (pos.y > 0) pos.y - 1 else 0;
    const ymax = std.math.min(pos.y + 1, ncols - 1);

    var x: usize = xmin;
    var y: usize = pos.y;

    while (x <= xmax) : (x += 1) {
        if (x == pos.x) {
            continue;
        }
        try procMove(height, Coord{ .x = x, .y = y }, dir, grid, visited, &moves);
    }

    x = pos.x;
    y = ymin;
    while (y <= ymax) : (y += 1) {
        if (y == pos.y) {
            continue;
        }
        try procMove(height, Coord{ .x = x, .y = y }, dir, grid, visited, &moves);
    }

    return moves;
}

fn getShortestPath(allocator: std.mem.Allocator, grid: Grid, nrows: usize, ncols: usize, start: Coord, ends: Grid, visited: *Grid, dir: Dir) !usize {
    var path_tips = std.ArrayList(PathTip).init(allocator);
    defer path_tips.deinit();
    try path_tips.append(PathTip{ .pos = start, .len = 0 });

    visited[start.x][start.y] = 1;

    while (path_tips.popOrNull()) |tip| {
        var moves = try getViableMoves(allocator, grid, nrows, ncols, visited.*, tip.pos, dir);
        defer moves.deinit();
        while (moves.popOrNull()) |new_pos| {
            if (ends[new_pos.x][new_pos.y] == 1) {
                return tip.len + 1;
            }
            visited[new_pos.x][new_pos.y] = 1;
            try path_tips.insert(0, PathTip{ .pos = new_pos, .len = tip.len + 1 });
        }
    }

    return std.math.maxInt(usize);
}

fn getAllPossibleStarts(grid: Grid, nrows: usize, ncols: usize) Grid {
    var starts = std.mem.zeroes(Grid);
    var row: usize = 0;
    while (row < nrows) : (row += 1) {
        var col: usize = 0;
        while (col < ncols) : (col += 1) {
            if (grid[row][col] == 0) {
                starts[row][col] = 1;
            }
        }
    }
    return starts;
}

fn solve1(path: []const u8) !usize {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    var nrows: usize = 0;
    var ncols: usize = 0;
    var start = Coord{};
    var end = Coord{};
    const grid = try createGrid(allocator, path, &nrows, &ncols, &start, &end);

    var visited = std.mem.zeroes(Grid);

    var ends = std.mem.zeroes(Grid);
    ends[end.x][end.y] = 1;

    return try getShortestPath(allocator, grid, nrows, ncols, start, ends, &visited, Dir.FWD);
}

fn solve2(path: []const u8) !usize {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    var nrows: usize = 0;
    var ncols: usize = 0;
    var start = Coord{};
    var end = Coord{};
    const grid = try createGrid(allocator, path, &nrows, &ncols, &start, &end);

    var visited = std.mem.zeroes(Grid);

    var starts = getAllPossibleStarts(grid, nrows, ncols);

    return try getShortestPath(allocator, grid, nrows, ncols, end, starts, &visited, Dir.REV);
}

fn example1() !usize {
    return solve1("problems/example_12.txt");
}

fn example2() !usize {
    return solve2("problems/example_12.txt");
}

fn part1() !usize {
    return solve1("problems/problem_12.txt");
}

fn part2() !usize {
    return solve2("problems/problem_12.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 31), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 29), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 528), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 522), ans);
}
