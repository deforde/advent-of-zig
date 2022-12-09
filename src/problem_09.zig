const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Coord = struct {
    x: i32 = 0,
    y: i32 = 0,
};

fn moveTail(head: Coord, tail: *Coord, tail_positions: *std.ArrayList(Coord)) anyerror!void {
    var delta_x = head.x - tail.*.x;
    var delta_y = head.y - tail.*.y;
    if (try std.math.absInt(delta_x) <= 1 and try std.math.absInt(delta_y) <= 1) {
        return;
    }

    if (delta_x != 0) {
        delta_x = @divTrunc(delta_x, try std.math.absInt(delta_x));
    }
    if (delta_y != 0) {
        delta_y = @divTrunc(delta_y, try std.math.absInt(delta_y));
    }

    tail.*.x += delta_x;
    tail.*.y += delta_y;

    var unique = true;
    for (tail_positions.*.items) |pos| {
        if (pos.x == tail.*.x and pos.y == tail.*.y) {
            unique = false;
            break;
        }
    }

    if (unique) {
        try tail_positions.*.append(tail.*);
    }
}

fn solve(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var head = Coord{};
    var tail = Coord{};
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
                    head.y += 1;
                    try moveTail(head, &tail, &tail_positions);
                }
            },
            'D' => {
                var i: i32 = 0;
                while (i < cnt) : (i += 1) {
                    head.y -= 1;
                    try moveTail(head, &tail, &tail_positions);
                }
            },
            'L' => {
                var i: i32 = 0;
                while (i < cnt) : (i += 1) {
                    head.x -= 1;
                    try moveTail(head, &tail, &tail_positions);
                }
            },
            'R' => {
                var i: i32 = 0;
                while (i < cnt) : (i += 1) {
                    head.x += 1;
                    try moveTail(head, &tail, &tail_positions);
                }
            },
            else => unreachable,
        }
    }

    const ans = tail_positions.items.len;
    return ans;
}

fn example1() anyerror!usize {
    return solve("problems/example_09.txt");
}

fn part1() anyerror!usize {
    return solve("problems/problem_09.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 13), ans);
}

test "par1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 6212), ans);
}
