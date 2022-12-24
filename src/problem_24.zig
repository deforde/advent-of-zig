const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Coord = struct {
    r: i32 = 0,
    c: i32 = 0,
};

const Dir = enum {
    NORTH,
    EAST,
    SOUTH,
    WEST,
};

const DirArr = [4]u8;

const BlizzMap = std.AutoHashMap(Coord, [4]u8);

fn initMap(allocator: std.mem.Allocator, path: []const u8, nrows: *i32, ncols: *i32) anyerror!BlizzMap {
    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var map = BlizzMap.init(allocator);

    var r: i32 = 0;
    var lines = std.mem.tokenize(u8, buf, "\n");
    _ = lines.next().?;
    while (lines.next()) |line| {
        if (line[1] == '#') {
            break;
        }
        var c: i32 = 0;
        for (line[1 .. line.len - 1]) |ch| {
            if (ch == '^' or ch == '>' or ch == 'v' or ch == '<') {
                var dir_arr = std.mem.zeroes(DirArr);
                switch (ch) {
                    '^' => dir_arr[@enumToInt(Dir.NORTH)] = 1,
                    '>' => dir_arr[@enumToInt(Dir.EAST)] = 1,
                    'v' => dir_arr[@enumToInt(Dir.SOUTH)] = 1,
                    '<' => dir_arr[@enumToInt(Dir.WEST)] = 1,
                    else => unreachable,
                }
                const coord = Coord{ .r = r, .c = c };
                try map.put(coord, dir_arr);
            }
            c += 1;
        }
        ncols.* = c;
        r += 1;
    }
    nrows.* = r;

    return map;
}

fn moveBlizz(pos: Coord, dir: Dir, nrows: i32, ncols: i32) Coord {
    switch (dir) {
        Dir.NORTH => {
            if (pos.r == 0) {
                return Coord{ .r = nrows - 1, .c = pos.c };
            }
            return Coord{ .r = pos.r - 1, .c = pos.c };
        },
        Dir.EAST => {
            if (pos.c == ncols - 1) {
                return Coord{ .r = pos.r, .c = 0 };
            }
            return Coord{ .r = pos.r, .c = pos.c + 1 };
        },
        Dir.SOUTH => {
            if (pos.r == nrows - 1) {
                return Coord{ .r = 0, .c = pos.c };
            }
            return Coord{ .r = pos.r + 1, .c = pos.c };
        },
        Dir.WEST => {
            if (pos.c == 0) {
                return Coord{ .r = pos.r, .c = ncols - 1 };
            }
            return Coord{ .r = pos.r, .c = pos.c - 1 };
        },
    }
}

fn updateMapEntry(map: *BlizzMap, pos: Coord, dir: Dir) anyerror!void {
    var blizz = map.getPtr(pos);
    if (blizz == null) {
        var dir_arr = std.mem.zeroes(DirArr);
        dir_arr[@enumToInt(dir)] = 1;
        try map.put(pos, dir_arr);
    } else {
        blizz.?[@enumToInt(dir)] += 1;
        std.debug.assert(blizz.?[@enumToInt(dir)] == 1 or blizz.?[@enumToInt(dir)] == 0);
    }
}

fn iterateMap(allocator: std.mem.Allocator, map: *BlizzMap, nrows: i32, ncols: i32) anyerror!void {
    var nmap = BlizzMap.init(allocator);

    var it = map.iterator();
    while (it.next()) |b| {
        const pos = b.key_ptr.*;
        const dir_arr = b.value_ptr.*;
        for (dir_arr) |cnt, i| {
            std.debug.assert(cnt == 0 or cnt == 1);
            if (cnt == 1) {
                const dir = @intToEnum(Dir, i);
                const npos = moveBlizz(pos, dir, nrows, ncols);
                try updateMapEntry(&nmap, npos, dir);
            }
        }
    }

    map.deinit();
    map.* = nmap;
}

fn appendIfOpen(map: *BlizzMap, moves: *std.ArrayList(Coord), pos: Coord) anyerror!void {
    if (map.get(pos) == null) {
        try moves.append(pos);
    }
}

fn getViableMoves(allocator: std.mem.Allocator, map: *BlizzMap, pos: Coord, nrows: i32, ncols: i32) anyerror!std.ArrayList(Coord) {
    var moves = std.ArrayList(Coord).init(allocator);

    try appendIfOpen(map, &moves, pos);

    if (pos.r == -1) {
        try appendIfOpen(map, &moves, Coord{ .r = 0, .c = 0 });
    } else {
        if (pos.r != 0) {
            try appendIfOpen(map, &moves, Coord{ .r = pos.r - 1, .c = pos.c });
        }
        if (pos.r != nrows - 1) {
            try appendIfOpen(map, &moves, Coord{ .r = pos.r + 1, .c = pos.c });
        }
        if (pos.c != 0) {
            try appendIfOpen(map, &moves, Coord{ .r = pos.r, .c = pos.c - 1 });
        }
        if (pos.c != ncols - 1) {
            try appendIfOpen(map, &moves, Coord{ .r = pos.r, .c = pos.c + 1 });
        }
    }

    return moves;
}

fn isContained(paths: *std.ArrayList(Coord), pos: Coord) bool {
    for (paths.items) |pt| {
        if (pt.r == pos.r and pt.c == pos.c) {
            return true;
        }
    }
    return false;
}

fn appendUnique(paths: *std.ArrayList(Coord), pos: Coord) anyerror!void {
    if (!isContained(paths, pos)) {
        try paths.append(pos);
    }
}

fn solve(path: []const u8) anyerror!i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var nrows: i32 = 0;
    var ncols: i32 = 0;
    var map = try initMap(allocator, path, &nrows, &ncols);
    defer map.deinit();

    // std.debug.print("\n{} {}\n", .{ nrows, ncols });

    var paths = std.ArrayList(Coord).init(allocator);
    defer paths.deinit();
    try paths.append(Coord{ .r = -1, .c = 0 });

    var min: i32 = 0;
    while (true) : (min += 1) {
        try iterateMap(allocator, &map, nrows, ncols);
        var npaths = std.ArrayList(Coord).init(allocator);
        for (paths.items) |path_tip| {
            var moves = try getViableMoves(allocator, &map, path_tip, nrows, ncols);
            defer moves.deinit();
            while (moves.popOrNull()) |npos| {
                if (npos.r == nrows - 1 and npos.c == ncols - 1) {
                    npaths.deinit();
                    // +1 to move to this pos, +1 again to move to exit
                    return min + 2;
                }
                try appendUnique(&npaths, npos);
            }
        }
        paths.deinit();
        paths = npaths;
    }
    unreachable;
}

fn example1() anyerror!i32 {
    return solve("problems/example_24.txt");
}

fn part1() anyerror!i32 {
    return solve("problems/problem_24.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(i32, 18), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i32, 18), ans);
}
