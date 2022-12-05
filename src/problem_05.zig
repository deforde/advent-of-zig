const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn solve(path: []const u8, simultaneous: bool) anyerror![9]u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var crate_stacks = [9]std.ArrayList(u8){
        std.ArrayList(u8).init(allocator),
        std.ArrayList(u8).init(allocator),
        std.ArrayList(u8).init(allocator),
        std.ArrayList(u8).init(allocator),
        std.ArrayList(u8).init(allocator),
        std.ArrayList(u8).init(allocator),
        std.ArrayList(u8).init(allocator),
        std.ArrayList(u8).init(allocator),
        std.ArrayList(u8).init(allocator),
    };

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        if (line[1] == '1') {
            continue;
        }
        if (line[0] == 'm') {
            var elems = std.mem.split(u8, line, " ");
            _ = elems.next();
            const cnt = try std.fmt.parseInt(usize, elems.next().?, 10);
            _ = elems.next();
            const src = try std.fmt.parseInt(usize, elems.next().?, 10) - 1;
            _ = elems.next();
            const dst = try std.fmt.parseInt(usize, elems.next().?, 10) - 1;
            if (simultaneous) {
                var temp = std.ArrayList(u8).init(allocator);
                defer temp.deinit();
                var x: usize = 0;
                while (x < cnt) : (x += 1) {
                    try temp.append(crate_stacks[src].pop());
                }
                x = 0;
                while (x < cnt) : (x += 1) {
                    try crate_stacks[dst].append(temp.pop());
                }
            } else {
                var x: usize = 0;
                while (x < cnt) : (x += 1) {
                    try crate_stacks[dst].append(crate_stacks[src].pop());
                }
            }
            continue;
        }
        var i: usize = 1;
        while (i < line.len) : (i += 4) {
            const ch = line[i];
            const stack_id = (i - 1) / 4;
            if (ch >= 'A' and ch <= 'Z') {
                try crate_stacks[stack_id].insert(0, ch);
            }
        }
    }

    var ans = [9]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    for (crate_stacks) |stack, idx| {
        if (stack.items.len != 0) {
            ans[idx] = stack.items[stack.items.len - 1];
        }
        stack.deinit();
    }

    return ans;
}

fn example1() anyerror![9]u8 {
    return solve("problems/example_05.txt", false);
}

fn example2() anyerror![9]u8 {
    return solve("problems/example_05.txt", true);
}

fn part1() anyerror![9]u8 {
    return solve("problems/problem_05.txt", false);
}

fn part2() anyerror![9]u8 {
    return solve("problems/problem_05.txt", true);
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual([_]u8{ 'C', 'M', 'Z', 0, 0, 0, 0, 0, 0 }, ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual([9]u8{ 'R', 'F', 'F', 'F', 'W', 'B', 'P', 'N', 'S' }, ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual([_]u8{ 'M', 'C', 'D', 0, 0, 0, 0, 0, 0 }, ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual([9]u8{ 'C', 'Q', 'Q', 'B', 'B', 'J', 'F', 'C', 'S' }, ans);
}
