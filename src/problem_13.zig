const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Node = struct {
    parent: ?*Node = null,
    children: std.ArrayList(Node),
    val: ?i32 = null,
    divider: bool = false,

    pub fn descend(self: *Node, allocator: std.mem.Allocator) anyerror!*Node {
        try self.children.append(Node{
            .parent = self,
            .children = std.ArrayList(Node).init(allocator),
        });
        return &self.children.items[self.children.items.len - 1];
    }

    pub fn ascend(self: *Node) anyerror!*Node {
        return self.parent.?;
    }

    pub fn print(self: *const Node, allocator: std.mem.Allocator, indent: []const u8) anyerror!void {
        std.debug.print("{s}{}\n", .{ indent, self.val orelse -1 });
        const new_indent = try std.fmt.allocPrint(allocator, "{s}  ", .{indent});
        defer allocator.free(new_indent);
        for (self.children.items) |*child| {
            try child.print(allocator, new_indent);
        }
    }

    pub fn convertValToChild(self: *Node, allocator: std.mem.Allocator) anyerror!void {
        std.debug.assert(self.val != null);
        const val = self.val;
        self.val = null;
        var child = try self.descend(allocator);
        child.*.val = val;
    }

    pub fn deinit(self: *Node) void {
        for (self.children.items) |*child| {
            child.deinit();
        }
        self.children.deinit();
    }
};

fn genNode(allocator: std.mem.Allocator, s: []const u8) anyerror!Node {
    std.debug.assert(s[0] == '[');

    var root = Node{
        .children = std.ArrayList(Node).init(allocator),
    };
    var cur = &root;
    var num_str: [128]u8 = undefined;
    var idx: usize = 0;

    for (s) |ch| {
        switch (ch) {
            '[' => {
                cur = try cur.descend(allocator);
            },
            ']' => {
                var val: ?i32 = null;
                if (idx > 0) {
                    val = try std.fmt.parseInt(i32, num_str[0..idx], 10);
                    idx = 0;
                    cur.val = val;
                }
                cur = try cur.ascend();
            },
            ',' => {
                var val: ?i32 = null;
                if (idx > 0) {
                    val = try std.fmt.parseInt(i32, num_str[0..idx], 10);
                    idx = 0;
                    cur.val = val;
                }
                cur = try cur.ascend();
                cur = try cur.descend(allocator);
            },
            else => {
                num_str[idx] = ch;
                idx += 1;
            },
        }
    }

    return root;
}

fn compareNodes(allocator: std.mem.Allocator, p: *Node, q: *Node) anyerror!i32 {
    var l = p;
    var r = q;

    // std.debug.print("compare:\n", .{});
    // try p.print(allocator, "  ");
    // try q.print(allocator, "  ");

    if (l.*.val != null and r.*.val != null) {
        if (l.*.val.? < r.*.val.?) {
            return 1;
        } else if (l.*.val.? > r.*.val.?) {
            return -1;
        }
    } else if (l.*.children.items.len > 0 and r.*.children.items.len > 0) {
        var i: usize = 0;
        var j: usize = 0;
        while (i < l.*.children.items.len and j < r.*.children.items.len) {
            var l2 = &l.*.children.items[i];
            var r2 = &r.*.children.items[j];
            const res = try compareNodes(allocator, l2, r2);
            if (res != 0) {
                return res;
            }
            i += 1;
            j += 1;
        }
        if (i == l.*.children.items.len and j == r.*.children.items.len) {
            return 0;
        }
        if (i == l.*.children.items.len and j < r.*.children.items.len) {
            return 1;
        }
        if (i < l.*.children.items.len and j == r.*.children.items.len) {
            return -1;
        }
    } else if (l.*.val != null) {
        try l.convertValToChild(allocator);
        const res = try compareNodes(allocator, l, r);
        if (res != 0) {
            return res;
        }
    } else if (r.*.val != null) {
        try r.convertValToChild(allocator);
        const res = try compareNodes(allocator, l, r);
        if (res != 0) {
            return res;
        }
    } else if (l.*.children.items.len == 0 and r.*.children.items.len > 0) {
        return 1;
    } else if (l.*.children.items.len > 0 and r.*.children.items.len == 0) {
        return -1;
    }
    return 0;
}

fn sortPackets(allocator: std.mem.Allocator, packets: *std.ArrayList(Node)) anyerror!void {
    var change_made = true;
    while (change_made) {
        change_made = false;
        var i: usize = 0;
        while (i < packets.items.len - 1) : (i += 1) {
            var l = packets.items[i];
            var r = packets.items[i + 1];
            const sorted = try compareNodes(allocator, &l, &r) == 1;
            if (!sorted) {
                packets.items[i] = r;
                packets.items[i + 1] = l;
                change_made = true;
            }
        }
    }
}

fn solve1(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var sum: usize = 0;
    var idx: usize = 1;
    var blocks = std.mem.split(u8, buf, "\n\n");
    while (blocks.next()) |block| {
        var lines = std.mem.tokenize(u8, block, "\n");

        var p = try genNode(allocator, lines.next().?);
        defer p.deinit();

        var q = try genNode(allocator, lines.next().?);
        defer q.deinit();

        const res = try compareNodes(allocator, &p, &q);
        std.debug.assert(res != 0);
        if (res == 1) {
            sum += idx;
        }
        // std.debug.print("\n{}\n\n", .{res});

        // std.debug.print("\n", .{});
        // try p.print(allocator, "");
        // try q.print(allocator, "");

        idx += 1;
    }

    return sum;
}

fn solve2(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var packets = std.ArrayList(Node).init(allocator);
    defer {
        for (packets.items) |*packet| {
            packet.deinit();
        }
        packets.deinit();
    }
    try packets.append(try genNode(allocator, "[[2]]"));
    packets.items[packets.items.len - 1].divider = true;
    try packets.append(try genNode(allocator, "[[6]]"));
    packets.items[packets.items.len - 1].divider = true;

    var blocks = std.mem.split(u8, buf, "\n\n");
    while (blocks.next()) |block| {
        var lines = std.mem.tokenize(u8, block, "\n");
        try packets.append(try genNode(allocator, lines.next().?));
        try packets.append(try genNode(allocator, lines.next().?));
    }

    try sortPackets(allocator, &packets);

    var prod: usize = 1;
    var i: usize = 1;
    for (packets.items) |*packet| {
        // std.debug.print("\n", .{});
        // try packet.print(allocator, "");
        if (packet.*.divider) {
            prod *= i;
        }
        i += 1;
    }

    return prod;
}

fn example1() anyerror!usize {
    return solve1("problems/example_13.txt");
}

fn example2() anyerror!usize {
    return solve2("problems/example_13.txt");
}

fn part1() anyerror!usize {
    return solve1("problems/problem_13.txt");
}

fn part2() anyerror!usize {
    return solve2("problems/problem_13.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 13), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 140), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 5208), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 25792), ans);
}
