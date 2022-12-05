const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

fn solve1(path: []const u8) anyerror![9]u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    // var crate_stacks = std.ArrayList(*std.ArrayList(u8)).init(allocator);
    // defer crate_stacks.deinit();
    // var j: usize = 0;
    // while (j < 3) : (j += 1) {
    //     var list = std.ArrayList(u8).init(allocator);
    //     try crate_stacks.append(&list);
    // }
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
    // var j: usize = 0;
    // while (j < 3) : (j += 1) {
    //     var list = std.ArrayList(u8).init(allocator);
    //     crate_stacks[j] = &list;
    // }

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        if (line[1] == '1') {
            // for (crate_stacks) |stack| {
            //     std.debug.print("{s}\n", .{stack.items});
            // }
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
            // std.debug.print("{}, {}, {}\n", .{ cnt, src, dst });
            var temp = std.ArrayList(u8).init(allocator);
            defer temp.deinit();
            var x: usize = 0;
            while (x < cnt) : (x += 1) {
                // try crate_stacks[dst].append(crate_stacks[src].pop());
                try temp.append(crate_stacks[src].pop());
            }
            x = 0;
            while (x < cnt) : (x += 1) {
                // try crate_stacks[dst].append(crate_stacks[src].pop());
                try crate_stacks[dst].append(temp.pop());
            }
            continue;
        }
        var i: usize = 1;
        while (i < line.len) : (i += 4) {
            const ch = line[i];
            // std.debug.print("ch = {c}\n", .{ch});
            const stack_id = (i - 1) / 4;
            if (ch >= 'A' and ch <= 'Z') {
                // while (stack_id >= crate_stacks.items.len) {
                //     var list = std.ArrayList(u8).init(allocator);
                //     try crate_stacks.append(&list);
                // }
                // std.debug.print("{} -> {c}\n", .{ stack_id, ch });
                // try crate_stacks.items[stack_id].*.append(ch);
                try crate_stacks[stack_id].insert(0, ch);
            }
        }
    }

    var ans = [9]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    for (crate_stacks) |stack, idx| {
        ans[idx] = stack.items[stack.items.len - 1];
        stack.deinit();
        // std.debug.print("{s}\n", .{stack.items});
    }

    std.debug.print("{s}\n", .{ans});
    return ans;
}

// CMZ
// fn example1() anyerror![3]u8 {
//     return solve1("problems/example_05.txt");
// }

// MCD
// fn example2() anyerror!i32 {
//     return solve2("problems/example_05.txt");
// }

// RFFFWBPNS
fn part1() anyerror![9]u8 {
    return solve1("problems/problem_05.txt");
}

// CQQBBJFCS
// fn part2() anyerror!i32 {
//     return solve2("problems/problem_05.txt");
// }

// test "example1" {
//     const ans = try example1();
//     try std.testing.expectEqual([3]u8{ 'C', 'M', 'Z' }, ans);
// }

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual([9]u8{
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
    }, ans);
}

// test "example2" {
//     const ans = try example2();
//     try std.testing.expectEqual(@as(i32, 4), ans);
// }
//
// test "part2" {
//     const ans = try part2();
//     try std.testing.expectEqual(@as(i32, 841), ans);
// }
