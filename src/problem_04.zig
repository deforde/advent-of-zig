const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn solve1(path: []const u8) anyerror!i32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var count: i32 = 0;
    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var values = std.mem.tokenize(u8, line, "-,");
        const e1_1 = try std.fmt.parseInt(i32, values.next().?, 10);
        const e1_2 = try std.fmt.parseInt(i32, values.next().?, 10);
        const e2_1 = try std.fmt.parseInt(i32, values.next().?, 10);
        const e2_2 = try std.fmt.parseInt(i32, values.next().?, 10);
        if ((e1_1 >= e2_1 and e1_2 <= e2_2) or (e2_1 >= e1_1 and e2_2 <= e1_2)) {
            count += 1;
        }
    }

    return count;
}

fn solve2(path: []const u8) anyerror!i32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var count: i32 = 0;
    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var values = std.mem.tokenize(u8, line, "-,");
        const e1_1 = try std.fmt.parseInt(i32, values.next().?, 10);
        const e1_2 = try std.fmt.parseInt(i32, values.next().?, 10);
        const e2_1 = try std.fmt.parseInt(i32, values.next().?, 10);
        const e2_2 = try std.fmt.parseInt(i32, values.next().?, 10);
        const start = std.math.max(e1_1, e2_1);
        const end = std.math.min(e1_2, e2_2);
        if (end >= start) {
            count += 1;
        }
    }

    return count;
}

fn example1() anyerror!i32 {
    return solve1("problems/example_04.txt");
}

fn example2() anyerror!i32 {
    return solve2("problems/example_04.txt");
}

fn part1() anyerror!i32 {
    return solve1("problems/problem_04.txt");
}

fn part2() anyerror!i32 {
    return solve2("problems/problem_04.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(i32, 2), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i32, 534), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(i32, 4), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i32, 841), ans);
}
