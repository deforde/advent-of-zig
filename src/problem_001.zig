const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

pub fn part1() anyerror!i32 {
    const allocator = std.heap.page_allocator;
    const buf = try readFileIntoBuf(allocator, "problems/problem_001.txt");
    var tokens = std.mem.tokenize(u8, buf, "\n");
    var prev = try std.fmt.parseInt(i32, tokens.next().?, 10);
    var inc: i32 = 0;
    while (tokens.next()) |token| {
        const cur = try std.fmt.parseInt(i32, token, 10);
        if (cur > prev) {
            inc += 1;
        }
        prev = cur;
    }
    return inc;
}

pub fn part2() anyerror!i32 {
    const allocator = std.heap.page_allocator;
    const buf = try readFileIntoBuf(allocator, "problems/problem_001.txt");
    var tokens = std.mem.tokenize(u8, buf, "\n");
    var inc: i32 = 0;
    var win = [_]i32{ 0, 0, 0 };
    var idx: i32 = 0;
    var prev_sum: i32 = 0;
    while (tokens.next()) |token| {
        const cur = try std.fmt.parseInt(i32, token, 10);

        var cur_sum: i32 = 0;
        var i: usize = 1;
        while (i < win.len) : (i += 1) {
            win[i - 1] = win[i];
            cur_sum += win[i - 1];
        }
        win[win.len - 1] = cur;
        cur_sum += cur;

        if (idx > 2 and cur_sum > prev_sum) {
            inc += 1;
        }

        prev_sum = cur_sum;
        idx += 1;
    }
    return inc;
}

test "part_001" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i32, 1583), ans);
}

test "part_002" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i32, 1627), ans);
}
