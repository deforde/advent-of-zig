const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Coord = struct {
    x: isize = 0,
    y: isize = 0,
};

const Map = std.AutoHashMap(Coord, u8);

fn solve(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var map = Map.init(allocator);
    defer map.deinit();

    var xmin: isize = std.math.maxInt(isize);
    var xmax: isize = 0;
    var ymax: isize = 0;

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var geo = std.ArrayList(Coord).init(allocator);
        defer geo.deinit();

        var coords = std.mem.tokenize(u8, line, " -> ");
        while (coords.next()) |coord| {
            var elems = std.mem.tokenize(u8, coord, ",");
            const x = try std.fmt.parseInt(isize, elems.next().?, 10);
            const y = try std.fmt.parseInt(isize, elems.next().?, 10);
            xmin = std.math.min(xmin, x);
            xmax = std.math.max(xmax, x);
            ymax = std.math.max(ymax, y);
            try geo.append(Coord{ .x = x, .y = y });
        }

        var i: usize = 0;
        while (i < geo.items.len - 1) : (i += 1) {
            const start = geo.items[i];
            const end = geo.items[i + 1];
            var dx = end.x - start.x;
            if (dx != 0) {
                dx = if (dx > 0) 1 else -1;
            }
            var dy = end.y - start.y;
            if (dy != 0) {
                dy = if (dy > 0) 1 else -1;
            }
            var cur = start;
            while (cur.x != end.x or cur.y != end.y) {
                // std.debug.print("{}, {}\n", .{ cur.x, cur.y });
                try map.put(cur, 0);
                cur.x += dx;
                cur.y += dy;
            }
            try map.put(end, 0);
        }
    }

    const sand_origin = Coord{ .x = 500, .y = 0 };
    var rst_cnt: usize = 0;
    var done = false;
    while (!done) {
        var grain = sand_origin;
        while (true) {
            var next_pos: [3]Coord = undefined;
            next_pos[0] = Coord{ .x = grain.x, .y = grain.y + 1 };
            next_pos[1] = Coord{ .x = grain.x - 1, .y = grain.y + 1 };
            next_pos[2] = Coord{ .x = grain.x + 1, .y = grain.y + 1 };
            var moved = false;
            for (next_pos) |pos| {
                if (map.get(pos) == null) {
                    moved = true;
                    grain = pos;
                    break;
                }
            }
            if (!moved) {
                // std.debug.print("{}, {}\n", .{ grain.x, grain.y });
                try map.put(grain, 0);
                rst_cnt += 1;
                break;
            }
            if (grain.y > ymax or grain.x < xmin or grain.x > xmax) {
                done = true;
                break;
            }
        }
    }

    return rst_cnt;
}

fn example1() anyerror!usize {
    return solve("problems/example_14.txt");
}

fn part1() anyerror!usize {
    return solve("problems/problem_14.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 24), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 1016), ans);
}
