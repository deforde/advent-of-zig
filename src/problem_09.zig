const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Coord = struct {
    x: i32 = 0,
    y: i32 = 0,
};

fn moveFollower(leader: Coord, follower: *Coord) !void {
    var delta_x = leader.x - follower.*.x;
    var delta_y = leader.y - follower.*.y;

    if (try std.math.absInt(delta_x) <= 1 and try std.math.absInt(delta_y) <= 1) {
        return;
    }

    if (delta_x != 0) {
        delta_x = if (delta_x > 0) 1 else -1;
    }
    if (delta_y != 0) {
        delta_y = if (delta_y > 0) 1 else -1;
    }

    follower.*.x += delta_x;
    follower.*.y += delta_y;
}

fn logTailPos(tail: Coord, tail_positions: *std.ArrayList(Coord)) !void {
    for (tail_positions.*.items) |pos| {
        if (pos.x == tail.x and pos.y == tail.y) {
            return;
        }
    }
    try tail_positions.*.append(tail);
}

fn simRope(rope: *std.ArrayList(Coord), tail_positions: *std.ArrayList(Coord)) !void {
    var i: usize = 0;
    while (i < rope.*.items.len - 1) : (i += 1) {
        try moveFollower(rope.*.items[i], &rope.*.items[i + 1]);
    }
    try logTailPos(rope.*.items[rope.items.len - 1], tail_positions);
}

fn solve(path: []const u8, nknots: usize) !usize {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var rope = std.ArrayList(Coord).init(allocator);
    defer rope.deinit();
    var j: usize = 0;
    while (j < nknots) : (j += 1) {
        try rope.append(Coord{});
    }
    var head = &rope.items[0];

    var tail_positions = std.ArrayList(Coord).init(allocator);
    defer tail_positions.deinit();
    try tail_positions.append(Coord{});

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var records = std.mem.tokenize(u8, line, " ");
        const dir = records.next().?[0];
        const cnt = try std.fmt.parseInt(i32, records.next().?, 10);
        switch (dir) {
            'U' => {
                var i: i32 = 0;
                while (i < cnt) : (i += 1) {
                    head.*.y += 1;
                    try simRope(&rope, &tail_positions);
                }
            },
            'D' => {
                var i: i32 = 0;
                while (i < cnt) : (i += 1) {
                    head.*.y -= 1;
                    try simRope(&rope, &tail_positions);
                }
            },
            'L' => {
                var i: i32 = 0;
                while (i < cnt) : (i += 1) {
                    head.*.x -= 1;
                    try simRope(&rope, &tail_positions);
                }
            },
            'R' => {
                var i: i32 = 0;
                while (i < cnt) : (i += 1) {
                    head.*.x += 1;
                    try simRope(&rope, &tail_positions);
                }
            },
            else => unreachable,
        }
    }

    const ans = tail_positions.items.len;
    return ans;
}

fn example1() !usize {
    return solve("problems/example_1_09.txt", 2);
}

fn example2() !usize {
    return solve("problems/example_2_09.txt", 10);
}

fn part1() !usize {
    return solve("problems/problem_09.txt", 2);
}

fn part2() !usize {
    return solve("problems/problem_09.txt", 10);
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 13), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 36), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 6212), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 2522), ans);
}
