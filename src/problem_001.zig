const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn getSumList() anyerror!std.ArrayList(i32) {
    const allocator = std.heap.page_allocator;
    const buf = try readFileIntoBuf(allocator, "problems/problem_001.txt");
    var tokens = std.mem.split(u8, buf, "\n");
    var sum: i32 = 0;
    var list = std.ArrayList(i32).init(allocator);
    while (tokens.next()) |token| {
        if (token.len == 0) {
            try list.append(sum);
            sum = 0;
        } else {
            const cur = try std.fmt.parseInt(i32, token, 10);
            sum += cur;
        }
    }
    try list.append(sum);
    std.sort.sort(i32, list.items, {}, std.sort.desc(i32));
    return list;
}

fn part1() anyerror!i32 {
    var list = try getSumList();
    defer list.deinit();
    return list.items[0];
}

fn part2() anyerror!i32 {
    var list = try getSumList();
    defer list.deinit();
    return list.items[0] + list.items[1] + list.items[2];
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i32, 67633), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i32, 199628), ans);
}
