const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const NodeTy = enum {
    NUM,
    ADD,
    SUB,
    MUL,
    DIV,
    EQL,
};

const Node = struct {
    nm: []const u8,
    ty: NodeTy,
    l: ?*Node = null,
    r: ?*Node = null,
    v: i64 = 0,
};

fn findNode(store: *std.ArrayList(Node), nm: []const u8) *Node {
    for (store.items) |*n| {
        if (std.mem.eql(u8, n.nm, nm)) {
            return n;
        }
    }
    unreachable;
}

fn calcNode(n: *Node, delta: ?*i64, rev: ?bool) i64 {
    if (n.ty == NodeTy.NUM) {
        return n.v;
    }
    const l = calcNode(n.l.?, null, null);
    const r = calcNode(n.r.?, null, null);
    switch (n.ty) {
        NodeTy.ADD => return l + r,
        NodeTy.SUB => return l - r,
        NodeTy.MUL => return l * r,
        NodeTy.DIV => return @divTrunc(l, r),
        NodeTy.EQL => {
            if (delta != null) {
                if (rev.?) {
                    delta.?.* = r - l;
                } else {
                    delta.?.* = l - r;
                }
            }
            // std.debug.print("{} == {}\n", .{ l, r });
            return if (l == r) 1 else 0;
        },
        else => unreachable,
    }
}

fn solve1(path: []const u8) anyerror!i64 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var store = std.ArrayList(Node).init(allocator);
    defer store.deinit();
    try store.ensureTotalCapacity(2587);

    var root: ?*Node = null;

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
            try store.append(n);
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
            try store.append(n);
        }
        if (std.mem.eql(u8, nm, "root")) {
            root = &store.items[store.items.len - 1];
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
        var n = findNode(&store, nm);
        n.l = findNode(&store, op1);
        n.r = findNode(&store, op2);
    }

    return calcNode(root.?, null, null);
}

fn solve2(path: []const u8, init_max: i64, rev: bool) anyerror!i64 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var store = std.ArrayList(Node).init(allocator);
    defer store.deinit();
    try store.ensureTotalCapacity(2587);

    var root: ?*Node = null;

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
            try store.append(n);
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
            try store.append(n);
        }
        if (std.mem.eql(u8, nm, "root")) {
            root = &store.items[store.items.len - 1];
            root.?.ty = NodeTy.EQL;
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
        var n = findNode(&store, nm);
        n.l = findNode(&store, op1);
        n.r = findNode(&store, op2);
    }

    var delta: i64 = std.math.maxInt(i64);
    var min: i64 = 0;
    var max = init_max;
    var n = findNode(&store, "humn");
    n.v = max;
    while (calcNode(root.?, &delta, rev) == 0) : (n.v = @divTrunc(max - min, 2) + min) {
        if (delta < 0) {
            min = n.v;
        } else {
            max = n.v;
        }
        // std.debug.print("{} - {}, {}, {}\n", .{ min, max, n.v, delta });
    }

    return n.v;
}

fn example1() anyerror!i64 {
    return solve1("problems/example_21.txt");
}

fn example2() anyerror!i64 {
    return solve2("problems/example_21.txt", 100000, false);
}

fn part1() anyerror!i64 {
    return solve1("problems/problem_21.txt");
}

fn part2() anyerror!i64 {
    return solve2("problems/problem_21.txt", 1000000000000000, true);
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
