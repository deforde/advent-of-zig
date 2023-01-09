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

fn walk1(grid: Grid, nrows: usize, ncols: usize, pos: Coord, dir: u8) Coord {
    var new_pos = pos;
    while (true) {
        switch (dir) {
            0 => { // East
                new_pos.c += 1;
                new_pos.c %= ncols;
            },
            1 => { // South
                new_pos.r += 1;
                new_pos.r %= nrows;
            },
            2 => { // West
                if (new_pos.c == 0) {
                    new_pos.c = ncols - 1;
                } else {
                    new_pos.c -= 1;
                }
            },
            3 => { // North
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

fn getRegion(pos: Coord) usize {
    switch (pos.c) {
        0...49 => {
            switch (pos.r) {
                100...149 => return 5,
                150...199 => return 6,
                else => unreachable,
            }
        },
        50...99 => {
            switch (pos.r) {
                0...49 => return 1,
                50...99 => return 3,
                100...149 => return 4,
                else => unreachable,
            }
        },
        100...149 => {
            switch (pos.r) {
                0...49 => return 2,
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

fn walk2(grid: Grid, pos: Coord, dir: *u8) Coord {
    const cur_reg = getRegion(pos);

    var new_pos = pos;
    var new_dir = dir.*;
    switch (cur_reg) {
        1 => {
            switch (dir.*) {
                0 => { // East
                    new_pos.c += 1;
                },
                1 => { // South
                    new_pos.r += 1;
                },
                2 => { // West
                    if (new_pos.c == 50) {
                        new_pos.r = 49 - (new_pos.r % 50) + 100;
                        new_pos.c = 0;
                        new_dir = 0;
                    } else {
                        new_pos.c -= 1;
                    }
                },
                3 => { // North
                    if (new_pos.r == 0) {
                        new_pos.r = new_pos.c % 50 + 150;
                        new_pos.c = 0;
                        new_dir = 0;
                    } else {
                        new_pos.r -= 1;
                    }
                },
                else => unreachable,
            }
        },
        2 => {
            switch (dir.*) {
                0 => { // East
                    if (new_pos.c == 149) {
                        new_pos.r = 49 - (new_pos.r % 50) + 100;
                        new_pos.c = 99;
                        new_dir = 2;
                    } else {
                        new_pos.c += 1;
                    }
                },
                1 => { // South
                    if (new_pos.r == 49) {
                        new_pos.r = new_pos.c % 50 + 50;
                        new_pos.c = 99;
                        new_dir = 2;
                    } else {
                        new_pos.r += 1;
                    }
                },
                2 => { // West
                    new_pos.c -= 1;
                },
                3 => { // North
                    if (new_pos.r == 0) {
                        new_pos.r = 199;
                        new_pos.c = new_pos.c % 50;
                        new_dir = 3;
                    } else {
                        new_pos.r -= 1;
                    }
                },
                else => unreachable,
            }
        },
        3 => {
            switch (dir.*) {
                0 => { // East
                    if (new_pos.c == 99) {
                        new_pos.c = new_pos.r % 50 + 100;
                        new_pos.r = 49;
                        new_dir = 3;
                    } else {
                        new_pos.c += 1;
                    }
                },
                1 => { // South
                    new_pos.r += 1;
                },
                2 => { // West
                    if (new_pos.c == 50) {
                        new_pos.c = new_pos.r % 50;
                        new_pos.r = 100;
                        new_dir = 1;
                    } else {
                        new_pos.c -= 1;
                    }
                },
                3 => { // North
                    new_pos.r -= 1;
                },
                else => unreachable,
            }
        },
        4 => {
            switch (dir.*) {
                0 => { // East
                    if (new_pos.c == 99) {
                        new_pos.r = 49 - (new_pos.r % 50);
                        new_pos.c = 149;
                        new_dir = 2;
                    } else {
                        new_pos.c += 1;
                    }
                },
                1 => { // South
                    if (new_pos.r == 149) {
                        new_pos.r = new_pos.c % 50 + 150;
                        new_pos.c = 49;
                        new_dir = 2;
                    } else {
                        new_pos.r += 1;
                    }
                },
                2 => { // West
                    new_pos.c -= 1;
                },
                3 => { // North
                    new_pos.r -= 1;
                },
                else => unreachable,
            }
        },
        5 => {
            switch (dir.*) {
                0 => { // East
                    new_pos.c += 1;
                },
                1 => { // South
                    new_pos.r += 1;
                },
                2 => { // West
                    if (new_pos.c == 0) {
                        new_pos.r = 49 - (new_pos.r % 50);
                        new_pos.c = 50;
                        new_dir = 0;
                    } else {
                        new_pos.c -= 1;
                    }
                },
                3 => { // North
                    if (new_pos.r == 100) {
                        new_pos.r = new_pos.c % 50 + 50;
                        new_pos.c = 50;
                        new_dir = 0;
                    } else {
                        new_pos.r -= 1;
                    }
                },
                else => unreachable,
            }
        },
        6 => {
            switch (dir.*) {
                0 => { // East
                    if (new_pos.c == 49) {
                        new_pos.c = new_pos.r % 50 + 50;
                        new_pos.r = 149;
                        new_dir = 3;
                    } else {
                        new_pos.c += 1;
                    }
                },
                1 => { // South
                    if (new_pos.r == 199) {
                        new_pos.c = new_pos.c % 50 + 100;
                        new_pos.r = 0;
                    } else {
                        new_pos.r += 1;
                    }
                },
                2 => { // West
                    if (new_pos.c == 0) {
                        new_pos.c = new_pos.r % 50 + 50;
                        new_pos.r = 0;
                        new_dir = 1;
                    } else {
                        new_pos.c -= 1;
                    }
                },
                3 => { // North
                    new_pos.r -= 1;
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }
    if (grid[new_pos.r][new_pos.c] == '#') {
        new_pos = pos;
    } else {
        dir.* = new_dir;
    }

    return new_pos;
}

fn solve1(path: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

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
    for (instr) |ch| {
        if (ch >= '0' and ch <= '9') {
            numstr[numstr_idx] = ch;
            numstr_idx += 1;
            continue;
        }
        const cnt = try std.fmt.parseInt(usize, numstr[0..numstr_idx], 10);
        numstr_idx = 0;
        var j: usize = 0;
        while (j < cnt) : (j += 1) {
            pos = walk1(grid, nrows, ncols, pos, dir);
        }
        // std.debug.print("{}, {c}\n", .{ pos, ch });
        if (ch == '\n') {
            break;
        }
        dir = rotate(dir, ch);
    }

    const ans: usize = 1000 * (pos.r + 1) + 4 * (pos.c + 1) + dir;
    return ans;
}

fn solve2(path: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var strt = Coord{};
    var grid = std.mem.zeroes(Grid);

    var blocks = std.mem.split(u8, buf, "\n\n");

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
        i += 1;
    }

    // std.debug.print("\n{}, {}, {}\n", .{ nrows, ncols, strt });

    var pos = strt;
    var dir: u8 = 0;
    const instr = blocks.next().?;
    var numstr = [_]u8{0} ** 128;
    var numstr_idx: usize = 0;
    for (instr) |ch| {
        if (ch >= '0' and ch <= '9') {
            numstr[numstr_idx] = ch;
            numstr_idx += 1;
            continue;
        }
        const cnt = try std.fmt.parseInt(usize, numstr[0..numstr_idx], 10);
        numstr_idx = 0;
        var j: usize = 0;
        while (j < cnt) : (j += 1) {
            pos = walk2(grid, pos, &dir);
        }
        // std.debug.print("{}, {c}\n", .{ pos, ch });
        if (ch == '\n') {
            break;
        }
        dir = rotate(dir, ch);
    }

    const ans: usize = 1000 * (pos.r + 1) + 4 * (pos.c + 1) + dir;
    return ans;
}

fn example1() !usize {
    return solve1("problems/example_22.txt");
}

fn part1() !usize {
    return solve1("problems/problem_22.txt");
}

fn part2() !usize {
    return solve2("problems/problem_22.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 6032), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 27436), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 15426), ans);
}
