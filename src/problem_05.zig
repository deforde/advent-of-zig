const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn solve(path: []const u8, simultaneous: bool) ![9]u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

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
    defer {
        for (crate_stacks) |stack| {
            stack.deinit();
        }
    }

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
                const insert_idx = crate_stacks[dst].items.len;
                var x: usize = 0;
                while (x < cnt) : (x += 1) {
                    try crate_stacks[dst].insert(insert_idx, crate_stacks[src].pop());
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
            if (ch >= 'A' and ch <= 'Z') {
                const stack_id = (i - 1) / 4;
                try crate_stacks[stack_id].insert(0, ch);
            }
        }
    }

    var ans = [9]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    for (crate_stacks) |stack, idx| {
        if (stack.items.len == 0) {
            break;
        }
        ans[idx] = stack.items[stack.items.len - 1];
    }

    return ans;
}

fn example1() ![9]u8 {
    return solve("problems/example_05.txt", false);
}

fn example2() ![9]u8 {
    return solve("problems/example_05.txt", true);
}

fn part1() ![9]u8 {
    return solve("problems/problem_05.txt", false);
}

fn part2() ![9]u8 {
    return solve("problems/problem_05.txt", true);
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqualStrings("CMZ", ans[0..3]);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqualStrings("RFFFWBPNS", ans[0..]);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqualStrings("MCD", ans[0..3]);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqualStrings("CQQBBJFCS", ans[0..]);
}
