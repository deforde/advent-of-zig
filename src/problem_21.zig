const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const NodeTy = enum {
    NUM,
    ADD,
    SUB,
    MUL,
    DIV,
};

const Node = struct {
    nm: []const u8,
    ty: NodeTy,
    l: ?*Node = null,
    r: ?*Node = null,
    v: i64 = 0,
};

const BackingStore = [2587]Node;

fn findNode(store: *BackingStore, nm: []const u8) *Node {
    for (store) |*n| {
        if (std.mem.eql(u8, n.nm, nm)) {
            return n;
        }
    }
    unreachable;
}

fn calcNode(n: *Node) i64 {
    if (n.ty == NodeTy.NUM) {
        return n.v;
    }
    const l = calcNode(n.l.?);
    const r = calcNode(n.r.?);
    switch (n.ty) {
        NodeTy.ADD => return l + r,
        NodeTy.SUB => return l - r,
        NodeTy.MUL => return l * r,
        NodeTy.DIV => return @divTrunc(l, r),
        else => unreachable,
    }
}

fn initNodes(buf: []const u8, store: *BackingStore, root: *?*Node) anyerror!void {
    var idx: usize = 0;

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var records = std.mem.tokenize(u8, line, " :");
        const nm = records.next().?;
        const op1 = records.next().?;
        if (op1[0] >= '0' and op1[0] <= '9') {
            const n = Node{
                .nm = nm,
                .ty = NodeTy.NUM,
                .v = try std.fmt.parseInt(i64, op1, 10),
            };
            store[idx] = n;
            idx += 1;
        } else {
            const op = records.next().?;
            const nty = switch (op[0]) {
                '+' => NodeTy.ADD,
                '-' => NodeTy.SUB,
                '*' => NodeTy.MUL,
                '/' => NodeTy.DIV,
                else => unreachable,
            };
            const n = Node{
                .nm = nm,
                .ty = nty,
            };
            store[idx] = n;
            idx += 1;
        }
        if (std.mem.eql(u8, nm, "root")) {
            root.* = &store[idx - 1];
        }
    }

    lines.reset();
    while (lines.next()) |line| {
        var records = std.mem.tokenize(u8, line, " :");
        const nm = records.next().?;
        const op1 = records.next().?;
        if (op1[0] >= '0' and op1[0] <= '9') {
            continue;
        }
        _ = records.next().?;
        const op2 = records.next().?;
        var n = findNode(store, nm);
        n.l = findNode(store, op1);
        n.r = findNode(store, op2);
    }
}

fn solve1(path: []const u8) anyerror!i64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var root: ?*Node = null;
    var store = std.mem.zeroes(BackingStore);
    try initNodes(buf, &store, &root);

    return calcNode(root.?);
}

fn solve2(path: []const u8) anyerror!i64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var root: ?*Node = null;
    var store = std.mem.zeroes(BackingStore);
    try initNodes(buf, &store, &root);

    root.?.ty = NodeTy.SUB;

    var min: i64 = 0;
    var max: i64 = 1000000000000000;
    var n = findNode(&store, "humn");
    n.v = max;

    if (calcNode(root.?) < 0) {
        var tmp = root.?.l;
        root.?.l = root.?.r;
        root.?.r = tmp;
    }

    while (true) {
        n.v = @divTrunc(max - min, 2) + min;
        var delta = calcNode(root.?);
        if (delta == 0) {
            while (calcNode(root.?) == 0) : (n.v -= 1) {}
            n.v += 1;
            break;
        } else if (delta > 0) {
            max = n.v;
        } else {
            min = n.v;
        }
    }

    return n.v;
}

fn example1() anyerror!i64 {
    return solve1("problems/example_21.txt");
}

fn example2() anyerror!i64 {
    return solve2("problems/example_21.txt");
}

fn part1() anyerror!i64 {
    return solve1("problems/problem_21.txt");
}

fn part2() anyerror!i64 {
    return solve2("problems/problem_21.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(i64, 152), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(i64, 301), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i64, 87457751482938), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i64, 3221245824363), ans);
}
