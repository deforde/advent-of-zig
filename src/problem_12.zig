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

const ShortestVisit = PathTip;

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

fn getViableMoves(allocator: std.mem.Allocator, grid: Grid, nrows: usize, ncols: usize, visited: *std.ArrayList(ShortestVisit), pos: Coord, path_len: usize) anyerror!std.ArrayList(Coord) {
    var moves = std.ArrayList(Coord).init(allocator);
    const pos_height = grid[pos.x][pos.y];

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
        const height = grid[x][y];
        if (height <= pos_height + 1) {
            const was_visited = wasVisitedOnShorterPath(visited, Coord{ .x = x, .y = y }, path_len + 1);
            if (!was_visited) {
                try moves.append(Coord{ .x = x, .y = y });
            }
        }
    }

    x = pos.x;
    y = ymin;
    while (y <= ymax) : (y += 1) {
        if (y == pos.y) {
            continue;
        }
        const height = grid[x][y];
        if (height <= pos_height + 1) {
            const was_visited = wasVisitedOnShorterPath(visited, Coord{ .x = x, .y = y }, path_len + 1);
            if (!was_visited) {
                try moves.append(Coord{ .x = x, .y = y });
            }
        }
    }

    return moves;
}

fn wasVisitedOnShorterPath(visited: *std.ArrayList(ShortestVisit), pos: Coord, len: usize) bool {
    var i: usize = 0;
    while (i < visited.items.len) : (i += 1) {
        if (pos.x == visited.items[i].pos.x and pos.y == visited.items[i].pos.y) {
            if (len >= visited.items[i].len) {
                return true;
            }
            visited.items[i].len = len;
            return false;
        }
    }
    return false;
}

fn addVisited(visited: *std.ArrayList(ShortestVisit), pos: Coord, len: usize) anyerror!void {
    var i: usize = 0;
    while (i < visited.items.len) : (i += 1) {
        if (pos.x == visited.items[i].pos.x and pos.y == visited.items[i].pos.y) {
            std.debug.assert(len <= visited.items[i].len);
            visited.items[i].len = len;
            return;
        }
    }
    try visited.append(ShortestVisit{ .pos = pos, .len = len });
}

fn getShortestPath(allocator: std.mem.Allocator, grid: Grid, nrows: usize, ncols: usize, start: Coord, end: Coord, visited: *std.ArrayList(ShortestVisit)) anyerror!usize {
    var path_tips = std.ArrayList(PathTip).init(allocator);
    defer path_tips.deinit();
    try path_tips.append(PathTip{ .pos = start, .len = 0 });

    if (wasVisitedOnShorterPath(visited, start, 0)) {
        return std.math.maxInt(usize);
    }
    try addVisited(visited, start, 0);

    while (path_tips.popOrNull()) |tip| {
        var moves = try getViableMoves(allocator, grid, nrows, ncols, visited, tip.pos, tip.len);
        defer moves.deinit();
        while (moves.popOrNull()) |new_pos| {
            if (new_pos.x == end.x and new_pos.y == end.y) {
                return tip.len + 1;
            }
            try addVisited(visited, new_pos, tip.len + 1);
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

    var visited = std.ArrayList(ShortestVisit).init(allocator);
    defer visited.deinit();

    return try getShortestPath(allocator, grid, nrows, ncols, start, end, &visited);
}

fn solve2(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var nrows: usize = 0;
    var ncols: usize = 0;
    var false_start = Coord{};
    var end = Coord{};
    const grid = try createGrid(allocator, path, &nrows, &ncols, &false_start, &end);

    var starts = try getAllPossibleStarts(allocator, grid, nrows, ncols);
    defer starts.deinit();

    var visited = std.ArrayList(ShortestVisit).init(allocator);
    defer visited.deinit();

    var shortest_path: usize = std.math.maxInt(usize);
    while (starts.popOrNull()) |start| {
        const this_shortest_path = try getShortestPath(allocator, grid, nrows, ncols, start, end, &visited);
        shortest_path = std.math.min(shortest_path, this_shortest_path);
    }
    return shortest_path;
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
