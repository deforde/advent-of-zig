const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Coord = struct {
    x: i64 = 0,
    y: i64 = 0,
};

const Range = struct {
    strt: i64 = 0,
    end: i64 = 0,

    fn merge(a: Range, b: Range) ?Range {
        const strt_max = std.math.max(a.strt, b.strt);
        const end_min = std.math.min(a.end, b.end);
        if (end_min >= strt_max) {
            return Range{
                .strt = std.math.min(a.strt, b.strt),
                .end = std.math.max(a.end, b.end),
            };
        }
        return null;
    }
};

const SBPair = struct {
    s: Coord = Coord{},
    b: Coord = Coord{},
    d: ?i64 = null,

    fn getDist(self: *SBPair) anyerror!i64 {
        if (self.d == null) {
            self.d = try std.math.absInt(self.b.x - self.s.x) + try std.math.absInt(self.b.y - self.s.y);
        }
        return self.d.?;
    }
};

fn getSBPairs(allocator: std.mem.Allocator, path: []const u8) anyerror!std.ArrayList(SBPair) {
    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var sbpairs = std.ArrayList(SBPair).init(allocator);

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var records = std.mem.tokenize(u8, line, " ,:=");
        _ = records.next().?;
        _ = records.next().?;
        _ = records.next().?;
        const sx = try std.fmt.parseInt(i64, records.next().?, 10);
        _ = records.next().?;
        const sy = try std.fmt.parseInt(i64, records.next().?, 10);
        _ = records.next().?;
        _ = records.next().?;
        _ = records.next().?;
        _ = records.next().?;
        _ = records.next().?;
        const bx = try std.fmt.parseInt(i64, records.next().?, 10);
        _ = records.next().?;
        const by = try std.fmt.parseInt(i64, records.next().?, 10);

        var sb = SBPair{
            .s = Coord{
                .x = sx,
                .y = sy,
            },
            .b = Coord{
                .x = bx,
                .y = by,
            },
        };
        _ = try sb.getDist();

        try sbpairs.append(sb);
    }

    return sbpairs;
}

fn addToRanges(allocator: std.mem.Allocator, ranges: *std.ArrayList(Range), range: Range) anyerror!void {
    for (ranges.items) |ext_range, i| {
        const merged = Range.merge(range, ext_range);
        if (merged != null) {
            _ = ranges.swapRemove(i);
            try addToRanges(allocator, ranges, merged.?);
            return;
        }
    }
    try ranges.append(range);
}

fn sumRanges(ranges: *std.ArrayList(Range)) i64 {
    var sum: i64 = 0;
    for (ranges.items) |range| {
        sum += range.end - range.strt;
    }
    return sum;
}

fn getRanges(allocator: std.mem.Allocator, sbpairs: *std.ArrayList(SBPair), y: i64) anyerror!std.ArrayList(Range) {
    var ranges = std.ArrayList(Range).init(allocator);

    for (sbpairs.items) |sbpair| {
        const d = sbpair.d.? - try std.math.absInt(sbpair.s.y - y);
        if (d < 0) {
            continue;
        }
        const xmin = sbpair.s.x - d;
        const xmax = sbpair.s.x + d;
        const r = Range{
            .strt = xmin,
            .end = xmax,
        };
        try addToRanges(allocator, &ranges, r);
    }

    return ranges;
}

fn solve1(path: []const u8, y: i64) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var sbpairs = try getSBPairs(allocator, path);
    defer sbpairs.deinit();

    var ranges = try getRanges(allocator, &sbpairs, y);
    defer ranges.deinit();

    const ans: usize = @intCast(usize, sumRanges(&ranges));
    return ans;
}

fn solve2(path: []const u8, xmax: i64, ymax: i64) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var sbpairs = try getSBPairs(allocator, path);
    defer sbpairs.deinit();

    // std.debug.print("\n", .{});
    var y: i64 = ymax;
    while (y >= 0) : (y -= 1) {
        // std.debug.print("{}/{}\r", .{ y + 1, ymax + 1 });
        var ranges = try getRanges(allocator, &sbpairs, y);
        defer ranges.deinit();
        if (ranges.items.len > 1 or ranges.items[0].strt > 0 or ranges.items[0].end < xmax) {
            for (ranges.items) |range| {
                if (range.strt > 0) {
                    // std.debug.print("\n{}, {}\n", .{ (range.strt - 1), y });
                    return @intCast(usize, 4000000 * (range.strt - 1) + y);
                } else if (range.end < xmax) {
                    // std.debug.print("\n{}, {}\n", .{ (range.end + 1), y });
                    return @intCast(usize, 4000000 * (range.end + 1) + y);
                }
            }
            unreachable;
        }
    }
    // std.debug.print("\n", .{});

    unreachable;
}

fn example1() anyerror!usize {
    return solve1("problems/example_15.txt", 10);
}

fn example2() anyerror!usize {
    return solve2("problems/example_15.txt", 20, 20);
}

fn part1() anyerror!usize {
    return solve1("problems/problem_15.txt", 2000000);
}

fn part2() anyerror!usize {
    return solve2("problems/problem_15.txt", 4000000, 4000000);
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 26), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 56000011), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 5335787), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 13673971349056), ans);
}
