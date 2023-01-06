const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Node = struct {
    x: i64 = 0,
    prev: ?*Node = null,
    next: ?*Node = null,
    mprev: ?*Node = null,
    mnext: ?*Node = null,
};

const NodeList = struct {
    head: ?*Node = null,
    tail: ?*Node = null,
    mhead: ?*Node = null,
    mtail: ?*Node = null,
};

fn printList(l: NodeList) void {
    var n = l.head.?;
    std.debug.print("\n", .{});
    while (n != l.tail.?) : (n = n.next.?) {
        std.debug.print("{} ", .{n.x});
    }
    std.debug.print("{}\n", .{n.x});
    n = l.mhead.?;
    while (n != l.mtail.?) : (n = n.mnext.?) {
        std.debug.print("{} ", .{n.x});
    }
    std.debug.print("{}\n", .{n.x});
}

fn doMix(l: *NodeList, n: *Node, len: usize) anyerror!void {
    const x = n.x;
    if (x != 0) {
        var mprev = n.mprev.?;
        var mnext = n.mnext.?;
        mprev.mnext = mnext;
        mnext.mprev = mprev;
        if (n == l.mhead) {
            l.mhead = mnext;
        } else if (n == l.mtail) {
            l.mtail = mprev;
        }

        var ins = mprev;
        const inc = @intCast(usize, try std.math.absInt(x)) % (len - 1);

        var i: usize = 0;
        while (i < inc) : (i += 1) {
            if (x > 0) {
                ins = ins.mnext.?;
            } else {
                ins = ins.mprev.?;
            }
        }

        mnext = ins.mnext.?;
        mnext.mprev = n;
        n.mnext = mnext;
        ins.mnext = n;
        n.mprev = ins;

        if (ins == l.mtail) {
            l.mtail = n;
        }

        // printList(l.*);
    }
}

fn mixList(l: *NodeList, len: usize) anyerror!void {
    var n = l.head.?;
    while (n != l.tail.?) : (n = n.next.?) {
        try doMix(l, n, len);
    }
    try doMix(l, n, len);
}

fn solve(path: []const u8, decrypt_key: i64, nmix: usize) anyerror!i64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var store = std.ArrayList(Node).init(allocator);
    defer store.deinit();
    try store.ensureTotalCapacity(5000);

    var prev: ?*Node = null;

    var list = NodeList{};

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        const x = try std.fmt.parseInt(i64, line, 10) * decrypt_key;
        try store.append(Node{});
        var n = &store.items[store.items.len - 1];
        n.x = x;
        n.prev = prev;
        n.mprev = prev;
        if (prev != null) {
            prev.?.next = n;
            prev.?.mnext = n;
        } else {
            list.head = n;
            list.mhead = n;
        }
        list.tail = n;
        list.mtail = n;
        prev = n;
    }

    prev.?.next = &store.items[0];
    prev.?.mnext = &store.items[0];
    store.items[0].prev = prev;
    store.items[0].mprev = prev;

    // printList(list);
    var j: usize = 0;
    while (j < nmix) : (j += 1) {
        try mixList(&list, store.items.len);
    }
    // printList(list);

    var sum: i64 = 0;
    var n = list.mhead;
    while (n.?.x != 0) : (n = n.?.mnext) {}
    n = n.?.mnext;
    var i: usize = 0;
    while (i < 3000) : (i += 1) {
        if ((i + 1) % 1000 == 0) {
            // std.debug.print("\n{}\n", .{n.?.x});
            sum += n.?.x;
        }
        n = n.?.mnext;
    }

    return sum;
}

fn example1() anyerror!i64 {
    return solve("problems/example_20.txt", 1, 1);
}

fn example2() anyerror!i64 {
    return solve("problems/example_20.txt", 811589153, 10);
}

fn part1() anyerror!i64 {
    return solve("problems/problem_20.txt", 1, 1);
}

fn part2() anyerror!i64 {
    return solve("problems/problem_20.txt", 811589153, 10);
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(i64, 3), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(i64, 1623178306), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i64, 6712), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i64, 1595584274798), ans);
}
