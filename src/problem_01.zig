const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn updateList(list: []i32, sum: i32) void {
    for (list) |val, idx| {
        if (sum > val) {
            list[idx] = sum;
            return;
        }
    }
}

fn getSumList() anyerror![3]i32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, "problems/problem_01.txt");
    defer allocator.free(buf);

    var tokens = std.mem.split(u8, buf, "\n");
    var sum: i32 = 0;
    var list = [3]i32{ 0, 0, 0 };
    while (tokens.next()) |token| {
        if (token.len == 0) {
            updateList(&list, sum);
            sum = 0;
        } else {
            const cur = try std.fmt.parseInt(i32, token, 10);
            sum += cur;
        }
    }
    updateList(&list, sum);
    std.sort.sort(i32, &list, {}, comptime std.sort.desc(i32));

    return list;
}

fn part1() anyerror!i32 {
    var list = try getSumList();
    return list[0];
}

fn part2() anyerror!i32 {
    var list = try getSumList();
    return list[0] + list[1] + list[2];
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i32, 67633), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i32, 199628), ans);
}
