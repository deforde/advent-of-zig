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

fn getViableMoves(allocator: std.mem.Allocator, grid: Grid, nrows: usize, ncols: usize, visited: *const std.ArrayList(Coord), pos: Coord) anyerror!std.ArrayList(Coord) {
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
            var was_visited = false;
            var i: usize = 0;
            while (i < visited.items.len) : (i += 1) {
                if (x == visited.items[i].x and y == visited.items[i].y) {
                    was_visited = true;
                    break;
                }
            }
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
            var was_visited = false;
            var i: usize = 0;
            while (i < visited.items.len) : (i += 1) {
                if (x == visited.items[i].x and y == visited.items[i].y) {
                    was_visited = true;
                    break;
                }
            }
            if (!was_visited) {
                try moves.append(Coord{ .x = x, .y = y });
            }
        }
    }

    return moves;
}

fn solve(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var nrows: usize = 0;
    var ncols: usize = 0;
    var start = Coord{};
    var end = Coord{};
    const grid = try createGrid(allocator, path, &nrows, &ncols, &start, &end);

    var path_tips = std.ArrayList(PathTip).init(allocator);
    defer path_tips.deinit();
    try path_tips.append(PathTip{ .pos = start, .len = 0 });

    var visited = std.ArrayList(Coord).init(allocator);
    defer visited.deinit();
    try visited.append(start);

    while (path_tips.popOrNull()) |tip| {
        var moves = try getViableMoves(allocator, grid, nrows, ncols, &visited, tip.pos);
        defer moves.deinit();
        while (moves.popOrNull()) |new_pos| {
            if (new_pos.x == end.x and new_pos.y == end.y) {
                return tip.len + 1;
            }
            try visited.append(new_pos);
            try path_tips.insert(0, PathTip{ .pos = new_pos, .len = tip.len + 1 });
        }
    }
    unreachable;
}

fn example1() anyerror!usize {
    return solve("problems/example_12.txt");
}

fn part1() anyerror!usize {
    return solve("problems/problem_12.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 31), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 528), ans);
}
