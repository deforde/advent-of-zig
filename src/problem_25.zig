const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;
const Allocator = @import("allocator.zig").Allocator;

const SNAFU = struct {
    n: [128]u8,
    l: usize = 0,
    fn getStr(self: *const SNAFU) []const u8 {
        return self.n[0..self.l];
    }
};

fn fromSNAFU(s: []const u8) i64 {
    var pos: i64 = @intCast(i64, s.len - 1);
    var n: i64 = 0;
    for (s) |c| {
        switch (c) {
            '0'...'9' => {
                n += (c - '0') * std.math.pow(i64, 5, pos);
            },
            '-' => {
                n -= std.math.pow(i64, 5, pos);
            },
            '=' => {
                n -= 2 * std.math.pow(i64, 5, pos);
            },
            else => unreachable,
        }
        pos -= 1;
    }
    return n;
}

fn toSNAFU(n: i64) SNAFU {
    var s = SNAFU{
        .n = undefined,
        .l = 0,
    };

    var x = n;
    while (x > 0) {
        var r = @mod(x, 5);
        switch (r) {
            0, 1, 2 => {
                s.n[s.l] = '0' + @intCast(u8, r);
                s.l += 1;
            },
            3 => {
                s.n[s.l] = '=';
                s.l += 1;
                x += 5;
            },
            4 => {
                s.n[s.l] = '-';
                s.l += 1;
                x += 5;
            },
            else => unreachable,
        }
        x = @divTrunc(x, 5);
    }

    std.mem.reverse(u8, s.n[0..s.l]);

    return s;
}

fn solve(path: []const u8) !SNAFU {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var sum: i64 = 0;

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        sum += fromSNAFU(line);
    }

    return toSNAFU(sum);
}

fn example1() !SNAFU {
    return solve("problems/example_25.txt");
}

fn part1() !SNAFU {
    return solve("problems/problem_25.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqualStrings("2=-1=0", ans.getStr());
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqualStrings("2-=2-0=-0-=0200=--21", ans.getStr());
}
