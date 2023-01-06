const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const p1_score_lookup = [_][3]i32{
    [_]i32{ 4, 8, 3 },
    [_]i32{ 1, 5, 9 },
    [_]i32{ 7, 2, 6 },
};

const p2_score_lookup = [_][3]i32{
    [_]i32{ 3, 4, 8 },
    [_]i32{ 1, 5, 9 },
    [_]i32{ 2, 6, 7 },
};

fn getTotalScore(path: []const u8, lookup: *const [3][3]i32) anyerror!i32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var lines = std.mem.tokenize(u8, buf, "\n");
    var sum: i32 = 0;
    while (lines.next()) |line| {
        var moves = std.mem.tokenize(u8, line, " ");
        const p1 = moves.next().?[0] - 'A';
        const p2 = moves.next().?[0] - 'X';
        sum += lookup[p1][p2];
    }
    return sum;
}

fn solve1(path: []const u8) anyerror!i32 {
    return try getTotalScore(path, &p1_score_lookup);
}

fn solve2(path: []const u8) anyerror!i32 {
    return try getTotalScore(path, &p2_score_lookup);
}

fn example1() anyerror!i32 {
    return solve1("problems/example_02.txt");
}

fn example2() anyerror!i32 {
    return solve2("problems/example_02.txt");
}

fn part1() anyerror!i32 {
    return solve1("problems/problem_02.txt");
}

fn part2() anyerror!i32 {
    return solve2("problems/problem_02.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(i32, 15), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i32, 11475), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(i32, 12), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i32, 16862), ans);
}
