const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn solve(path: []const u8, stm_cnt: usize) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var i: usize = stm_cnt - 1;
    while (i < buf.len) : (i += 1) {
        var bitset = std.bit_set.IntegerBitSet(26).initEmpty();
        var j: usize = i - (stm_cnt - 1);
        while (j <= i) : (j += 1) {
            bitset.set(@intCast(usize, buf[j] - 'a'));
        }
        if (bitset.count() == stm_cnt) {
            break;
        }
    }

    return i + 1;
}

fn example1() anyerror!usize {
    return solve("problems/example_1_06.txt", 4);
}

fn example2() anyerror!usize {
    return solve("problems/example_2_06.txt", 4);
}

fn example3() anyerror!usize {
    return solve("problems/example_3_06.txt", 4);
}

fn example4() anyerror!usize {
    return solve("problems/example_4_06.txt", 4);
}

fn example5() anyerror!usize {
    return solve("problems/example_5_06.txt", 4);
}

fn example1_2() anyerror!usize {
    return solve("problems/example_1_06.txt", 14);
}

fn example2_2() anyerror!usize {
    return solve("problems/example_2_06.txt", 14);
}

fn example3_2() anyerror!usize {
    return solve("problems/example_3_06.txt", 14);
}

fn example4_2() anyerror!usize {
    return solve("problems/example_4_06.txt", 14);
}

fn example5_2() anyerror!usize {
    return solve("problems/example_5_06.txt", 14);
}

fn part1() anyerror!usize {
    return solve("problems/problem_06.txt", 4);
}

fn part2() anyerror!usize {
    return solve("problems/problem_06.txt", 14);
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 7), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 5), ans);
}

test "example3" {
    const ans = try example3();
    try std.testing.expectEqual(@as(usize, 6), ans);
}

test "example4" {
    const ans = try example4();
    try std.testing.expectEqual(@as(usize, 10), ans);
}

test "example5" {
    const ans = try example5();
    try std.testing.expectEqual(@as(usize, 11), ans);
}

test "example1_2" {
    const ans = try example1_2();
    try std.testing.expectEqual(@as(usize, 19), ans);
}

test "example2_2" {
    const ans = try example2_2();
    try std.testing.expectEqual(@as(usize, 23), ans);
}

test "example3_2" {
    const ans = try example3_2();
    try std.testing.expectEqual(@as(usize, 23), ans);
}

test "example4_2" {
    const ans = try example4_2();
    try std.testing.expectEqual(@as(usize, 29), ans);
}

test "example5_2" {
    const ans = try example5_2();
    try std.testing.expectEqual(@as(usize, 26), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 1876), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 2202), ans);
}
