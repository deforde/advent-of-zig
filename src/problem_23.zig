const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;
const Allocator = @import("allocator.zig").Allocator;

const Coord = struct {
    x: i64 = 0,
    y: i64 = 0,
};

const ElfMap = std.AutoHashMap(Coord, Coord);

const DirList = std.ArrayList(u8);

fn createMap(allocator: std.mem.Allocator, path: []const u8) !ElfMap {
    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var map = ElfMap.init(allocator);

    var lines = std.mem.tokenize(u8, buf, "\n");
    var y: i64 = 0;
    while (lines.next()) |line| {
        for (line) |ch, x| {
            if (ch == '#') {
                try map.put(Coord{
                    .x = @intCast(i64, x),
                    .y = y,
                }, Coord{});
            }
        }
        y += 1;
    }

    return map;
}

fn getOccupied(map: *ElfMap, cache: *[3][3]u8, c: Coord, x: i64, y: i64) bool {
    if (cache[@intCast(usize, x - c.x + 1)][@intCast(usize, y - c.y + 1)] == 0) {
        if (map.contains(Coord{ .x = x, .y = y })) {
            cache[@intCast(usize, x - c.x + 1)][@intCast(usize, y - c.y + 1)] = 2;
            return true;
        } else {
            cache[@intCast(usize, x - c.x + 1)][@intCast(usize, y - c.y + 1)] = 1;
            return false;
        }
    } else if (cache[@intCast(usize, x - c.x + 1)][@intCast(usize, y - c.y + 1)] == 1) {
        return false;
    }
    return true;
}

fn moveElf(map: *ElfMap, dirs: *DirList, c: Coord) !Coord {
    var cnt: i64 = 0;
    var x: i64 = 0;
    var y: i64 = 0;

    var cache = [_][3]u8{
        [_]u8{
            0,
            0,
            0,
        },
        [_]u8{
            0,
            0,
            0,
        },
        [_]u8{
            0,
            0,
            0,
        },
    };

    cnt = 0;
    x = c.x - 1;
    while (x <= c.x + 1) : (x += 1) {
        y = c.y - 1;
        while (y <= c.y + 1) : (y += 1) {
            if (c.x == x and c.y == y) {
                continue;
            }
            if (getOccupied(map, &cache, c, x, y)) {
                cnt += 1;
            }
        }
    }
    if (cnt == 0) {
        return c;
    }

    for (dirs.items) |dir| {
        switch (dir) {
            'N' => {
                cnt = 0;
                x = c.x - 1;
                y = c.y - 1;
                while (x <= c.x + 1) : (x += 1) {
                    if (getOccupied(map, &cache, c, x, y)) {
                        cnt += 1;
                        break;
                    }
                }
                if (cnt == 0) {
                    return Coord{ .x = c.x, .y = c.y - 1 };
                }
            },
            'E' => {
                cnt = 0;
                x = c.x + 1;
                y = c.y - 1;
                while (y <= c.y + 1) : (y += 1) {
                    if (getOccupied(map, &cache, c, x, y)) {
                        cnt += 1;
                        break;
                    }
                }
                if (cnt == 0) {
                    return Coord{ .x = c.x + 1, .y = c.y };
                }
            },
            'S' => {
                cnt = 0;
                x = c.x - 1;
                y = c.y + 1;
                while (x <= c.x + 1) : (x += 1) {
                    if (getOccupied(map, &cache, c, x, y)) {
                        cnt += 1;
                        break;
                    }
                }
                if (cnt == 0) {
                    return Coord{ .x = c.x, .y = c.y + 1 };
                }
            },
            'W' => {
                cnt = 0;
                x = c.x - 1;
                y = c.y - 1;
                while (y <= c.y + 1) : (y += 1) {
                    if (getOccupied(map, &cache, c, x, y)) {
                        cnt += 1;
                        break;
                    }
                }
                if (cnt == 0) {
                    return Coord{ .x = c.x - 1, .y = c.y };
                }
            },
            else => unreachable,
        }
    }

    return c;
}

fn simMap(allocator: std.mem.Allocator, map: *ElfMap, dirs: *DirList) !bool {
    var nmap = ElfMap.init(allocator);
    var banned = ElfMap.init(allocator);
    defer banned.deinit();

    var mv_cnt: usize = 0;

    var it = map.iterator();
    while (it.next()) |e| {
        const dst = try moveElf(map, dirs, e.key_ptr.*);
        // std.debug.print("{} -> {}\n", .{ e.key_ptr.*, dst });
        if (banned.contains(dst)) {
            try nmap.put(e.key_ptr.*, e.key_ptr.*);
            continue;
        }
        const mv = nmap.getEntry(dst);
        if (mv != null) {
            const src = mv.?.value_ptr.*;
            _ = nmap.removeByPtr(mv.?.key_ptr);
            mv_cnt -= 1;
            try nmap.put(src, src);
            try banned.put(dst, dst);
            try nmap.put(e.key_ptr.*, e.key_ptr.*);
        } else {
            try nmap.put(dst, e.key_ptr.*);
            if (dst.x != e.key_ptr.*.x or dst.y != e.key_ptr.*.y) {
                mv_cnt += 1;
            }
        }
    }

    const dir = dirs.orderedRemove(0);
    try dirs.append(dir);

    const res = mv_cnt == 0;

    var omap = map.*;
    omap.deinit();
    map.* = nmap;

    return res;
}

fn countEmptyTiles(map: *ElfMap) i64 {
    var cnt: i64 = 0;

    var xmin: i64 = std.math.maxInt(i64);
    var xmax: i64 = std.math.minInt(i64);
    var ymin: i64 = std.math.maxInt(i64);
    var ymax: i64 = std.math.minInt(i64);

    var it = map.iterator();
    while (it.next()) |e| {
        xmin = std.math.min(xmin, e.key_ptr.x);
        xmax = std.math.max(xmax, e.key_ptr.x);
        ymin = std.math.min(ymin, e.key_ptr.y);
        ymax = std.math.max(ymax, e.key_ptr.y);
        cnt += 1;
    }

    cnt = (ymax - ymin + 1) * (xmax - xmin + 1) - cnt;

    return cnt;
}

fn printMap(map: *ElfMap) void {
    var xmin: i64 = std.math.maxInt(i64);
    var xmax: i64 = std.math.minInt(i64);
    var ymin: i64 = std.math.maxInt(i64);
    var ymax: i64 = std.math.minInt(i64);

    var it = map.iterator();
    while (it.next()) |e| {
        xmin = std.math.min(xmin, e.key_ptr.x);
        xmax = std.math.max(xmax, e.key_ptr.x);
        ymin = std.math.min(ymin, e.key_ptr.y);
        ymax = std.math.max(ymax, e.key_ptr.y);
    }

    // std.debug.print("\n{}, {}", .{ xmin, ymin });
    std.debug.print("\n", .{});
    var y: i64 = ymin;
    while (y <= ymax) : (y += 1) {
        var x: i64 = xmin;
        while (x <= xmax) : (x += 1) {
            if (map.get(Coord{ .x = x, .y = y }) != null) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn solve1(path: []const u8) !i64 {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = try createMap(allocator, path);
    defer map.deinit();
    // printMap(&map);

    var dirs = DirList.init(allocator);
    defer dirs.deinit();
    try dirs.append('N');
    try dirs.append('S');
    try dirs.append('W');
    try dirs.append('E');

    var i: i32 = 0;
    while (i < 10) : (i += 1) {
        _ = try simMap(allocator, &map, &dirs);
        // printMap(&map);
    }

    return countEmptyTiles(&map);
}

fn solve2(path: []const u8) !i64 {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = try createMap(allocator, path);
    defer map.deinit();
    // printMap(&map);

    var dirs = DirList.init(allocator);
    defer dirs.deinit();
    try dirs.append('N');
    try dirs.append('S');
    try dirs.append('W');
    try dirs.append('E');

    var i: i32 = 1;
    while (!try simMap(allocator, &map, &dirs)) : (i += 1) {}

    return i;
}

fn example1() !i64 {
    return solve1("problems/example_23.txt");
}

fn example2() !i64 {
    return solve2("problems/example_23.txt");
}

fn part1() !i64 {
    return solve1("problems/problem_23.txt");
}

fn part2() !i64 {
    return solve2("problems/problem_23.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(i64, 110), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(i64, 20), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i64, 4091), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i64, 1036), ans);
}
