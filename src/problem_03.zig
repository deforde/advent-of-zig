const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn solve1(path: []const u8) !i32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var sum: i32 = 0;
    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        const sz: usize = line.len;
        std.debug.assert(sz % 2 == 0);

        var c1 = std.ArrayList(i32).init(allocator);
        defer c1.deinit();
        for (line[0 .. sz / 2]) |char| {
            if (char > 'Z') {
                try c1.append(char - 'a' + 1);
            } else {
                try c1.append(char - 'A' + 27);
            }
        }
        std.sort.sort(i32, c1.items, {}, comptime std.sort.asc(i32));

        var c2 = std.ArrayList(i32).init(allocator);
        defer c2.deinit();
        for (line[sz / 2 ..]) |char| {
            if (char > 'Z') {
                try c2.append(char - 'a' + 1);
            } else {
                try c2.append(char - 'A' + 27);
            }
        }
        std.sort.sort(i32, c2.items, {}, comptime std.sort.asc(i32));

        var dup: i32 = -1;
        var idxC1: usize = 0;
        var idxC2: usize = 0;
        while (idxC1 < c1.items.len and idxC2 < c2.items.len) {
            if (c1.items[idxC1] == c2.items[idxC2]) {
                dup = c1.items[idxC1];
                break;
            }
            if (c1.items[idxC1] > c2.items[idxC2]) {
                idxC2 += 1;
            } else {
                idxC1 += 1;
            }
        }
        std.debug.assert(dup != -1);
        sum += dup;
    }

    return sum;
}

fn solve2(path: []const u8) !i32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var sum: i32 = 0;
    var lines = std.mem.tokenize(u8, buf, "\n");
    var group_idx: usize = 0;

    var c1 = std.ArrayList(i32).init(allocator);
    defer c1.deinit();
    var c2 = std.ArrayList(i32).init(allocator);
    defer c2.deinit();
    var c3 = std.ArrayList(i32).init(allocator);
    defer c3.deinit();

    var group = [_]*std.ArrayList(i32){
        &c1,
        &c2,
        &c3,
    };

    while (lines.next()) |line| {
        var c = group[group_idx];
        for (line) |char| {
            if (char > 'Z') {
                try c.*.append(char - 'a' + 1);
            } else {
                try c.*.append(char - 'A' + 27);
            }
        }
        std.sort.sort(i32, c.*.items, {}, comptime std.sort.asc(i32));
        if (group_idx == 2) {
            var dup: i32 = -1;

            var idxC1: usize = 0;
            var idxC2: usize = 0;
            var idxC3: usize = 0;
            while (idxC1 < c1.items.len and idxC2 < c2.items.len and idxC3 < c3.items.len) {
                const c1_val = c1.items[idxC1];
                const c2_val = c2.items[idxC2];
                const c3_val = c3.items[idxC3];
                const items = [_]i32{ c1_val, c2_val, c3_val };
                const max = std.mem.max(i32, &items);
                if (c1_val == c2_val and c1_val == c3_val) {
                    dup = c1_val;
                    break;
                }
                if (c1_val < max) {
                    idxC1 += 1;
                }
                if (c2_val < max) {
                    idxC2 += 1;
                }
                if (c3_val < max) {
                    idxC3 += 1;
                }
            }

            std.debug.assert(dup != -1);

            sum += dup;
            for (group) |list| {
                list.*.clearRetainingCapacity();
            }
            group_idx = 0;
            continue;
        }
        group_idx += 1;
    }

    return sum;
}

fn example1() !i32 {
    return solve1("problems/example_03.txt");
}

fn example2() !i32 {
    return solve2("problems/example_03.txt");
}

fn part1() !i32 {
    return solve1("problems/problem_03.txt");
}

fn part2() !i32 {
    return solve2("problems/problem_03.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(i32, 157), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i32, 7990), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(i32, 70), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i32, 2602), ans);
}
