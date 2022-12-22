const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Grid = [201][151]u8;

const Coord = struct {
    r: usize = 0,
    c: usize = 0,
};

fn rotate(dir: u8, rot: u8) u8 {
    switch (rot) {
        'R' => {
            return (dir + 1) % 4;
        },
        'L' => {
            if (dir == 0) {
                return 3;
            }
            return dir - 1;
        },
        else => unreachable,
    }
}

fn walk(grid: Grid, nrows: usize, ncols: usize, pos: Coord, dir: u8) Coord {
    var new_pos = pos;
    while (true) {
        switch (dir) {
            0 => {
                new_pos.c += 1;
                new_pos.c %= ncols;
            },
            1 => {
                new_pos.r += 1;
                new_pos.r %= nrows;
            },
            2 => {
                if (new_pos.c == 0) {
                    new_pos.c = ncols - 1;
                } else {
                    new_pos.c -= 1;
                }
            },
            3 => {
                if (new_pos.r == 0) {
                    new_pos.r = nrows - 1;
                } else {
                    new_pos.r -= 1;
                }
            },
            else => unreachable,
        }
        if (grid[new_pos.r][new_pos.c] != 0) {
            break;
        }
    }
    if (grid[new_pos.r][new_pos.c] == '#') {
        new_pos = pos;
    }
    return new_pos;
}

fn solve(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var strt = Coord{};
    var grid = std.mem.zeroes(Grid);

    var blocks = std.mem.split(u8, buf, "\n\n");

    var ncols: usize = 0;
    var i: usize = 0;
    var lines = std.mem.tokenize(u8, blocks.next().?, "\n");
    while (lines.next()) |line| {
        if (i == 0) {
            strt.c = std.mem.indexOf(u8, line, ".").?;
        }
        for (line) |ch, idx| {
            if (ch == '#' or ch == '.') {
                grid[i][idx] = ch;
            }
        }
        ncols = std.math.max(ncols, line.len);
        i += 1;
    }
    const nrows = i;

    // std.debug.print("\n{}, {}, {}\n", .{ nrows, ncols, strt });

    var pos = strt;
    var dir: u8 = 0;
    const instr = blocks.next().?;
    var numstr = [_]u8{0} ** 128;
    var numstr_idx: usize = 0;
    for (instr[0 .. instr.len - 1]) |ch| {
        if (ch >= '0' and ch <= '9') {
            numstr[numstr_idx] = ch;
            numstr_idx += 1;
            continue;
        }
        const cnt = try std.fmt.parseInt(usize, numstr[0..numstr_idx], 10);
        numstr_idx = 0;
        var j: usize = 0;
        while (j < cnt) : (j += 1) {
            pos = walk(grid, nrows, ncols, pos, dir);
        }
        // std.debug.print("{}\n", .{pos});
        dir = rotate(dir, ch);
    }

    const ans: usize = 1000 * (pos.r + 1) + 4 * (pos.c + 1) + dir;
    return ans;
}

fn example1() anyerror!usize {
    return solve("problems/example_22.txt");
}

fn part1() anyerror!usize {
    return solve("problems/problem_22.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 6032), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 6032), ans);
}
