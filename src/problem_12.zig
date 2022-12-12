const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Grid = [41][181]i32;

const Coord = struct {
    x: usize = 0,
    y: usize = 0,
};

const PathTip = struct {
    pos: Coord = Coord{},
    len: usize = 0,
};

const Dir = enum { FWD, REV };

fn createGrid(allocator: std.mem.Allocator, path: []const u8, nrows: *usize, ncols: *usize, start: *Coord, end: *Coord) anyerror!Grid {
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
            var height: i32 = 0;
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

fn procMove(height: i32, other_pos: Coord, dir: Dir, grid: Grid, visited: *std.ArrayList(Coord), moves: *std.ArrayList(Coord)) anyerror!void {
    const other_height = grid[other_pos.x][other_pos.y];
    const viable = switch (dir) {
        Dir.FWD => other_height <= height + 1,
        Dir.REV => height <= other_height + 1,
    };
    if (viable and !isContained(visited, other_pos)) {
        try moves.*.append(other_pos);
    }
}

fn getViableMoves(allocator: std.mem.Allocator, grid: Grid, nrows: usize, ncols: usize, visited: *std.ArrayList(Coord), pos: Coord, dir: Dir) anyerror!std.ArrayList(Coord) {
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

fn isContained(list: *std.ArrayList(Coord), pos: Coord) bool {
    var i: usize = 0;
    while (i < list.items.len) : (i += 1) {
        if (pos.x == list.items[i].x and pos.y == list.items[i].y) {
            return true;
        }
    }
    return false;
}

fn getShortestPath(allocator: std.mem.Allocator, grid: Grid, nrows: usize, ncols: usize, start: Coord, ends: *std.ArrayList(Coord), visited: *std.ArrayList(Coord), dir: Dir) anyerror!usize {
    var path_tips = std.ArrayList(PathTip).init(allocator);
    defer path_tips.deinit();
    try path_tips.append(PathTip{ .pos = start, .len = 0 });

    try visited.append(start);

    while (path_tips.popOrNull()) |tip| {
        var moves = try getViableMoves(allocator, grid, nrows, ncols, visited, tip.pos, dir);
        defer moves.deinit();
        while (moves.popOrNull()) |new_pos| {
            if (isContained(ends, new_pos)) {
                return tip.len + 1;
            }
            try visited.append(new_pos);
            try path_tips.insert(0, PathTip{ .pos = new_pos, .len = tip.len + 1 });
        }
    }

    return std.math.maxInt(usize);
}

fn getAllPossibleStarts(allocator: std.mem.Allocator, grid: Grid, nrows: usize, ncols: usize) anyerror!std.ArrayList(Coord) {
    var starts = std.ArrayList(Coord).init(allocator);
    var row: usize = 0;
    while (row < nrows) : (row += 1) {
        var col: usize = 0;
        while (col < ncols) : (col += 1) {
            if (grid[row][col] == 0) {
                try starts.append(Coord{ .x = row, .y = col });
            }
        }
    }
    return starts;
}

fn solve1(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var nrows: usize = 0;
    var ncols: usize = 0;
    var start = Coord{};
    var end = Coord{};
    const grid = try createGrid(allocator, path, &nrows, &ncols, &start, &end);

    var visited = std.ArrayList(Coord).init(allocator);
    defer visited.deinit();

    var ends = std.ArrayList(Coord).init(allocator);
    defer ends.deinit();
    try ends.append(end);

    return try getShortestPath(allocator, grid, nrows, ncols, start, &ends, &visited, Dir.FWD);
}

fn solve2(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var nrows: usize = 0;
    var ncols: usize = 0;
    var start = Coord{};
    var end = Coord{};
    const grid = try createGrid(allocator, path, &nrows, &ncols, &start, &end);

    var visited = std.ArrayList(Coord).init(allocator);
    defer visited.deinit();

    var starts = try getAllPossibleStarts(allocator, grid, nrows, ncols);
    defer starts.deinit();

    return try getShortestPath(allocator, grid, nrows, ncols, end, &starts, &visited, Dir.REV);
}

fn example1() anyerror!usize {
    return solve1("problems/example_12.txt");
}

fn example2() anyerror!usize {
    return solve2("problems/example_12.txt");
}

fn part1() anyerror!usize {
    return solve1("problems/problem_12.txt");
}

fn part2() anyerror!usize {
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
