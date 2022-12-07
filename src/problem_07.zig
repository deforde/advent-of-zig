const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Node = struct {
    parent: ?*Node = null,
    children: std.StringHashMap(Node),
    size: ?usize = null,

    pub fn addChild(self: *Node, allocator: std.mem.Allocator, name: []const u8, size: ?usize) anyerror!void {
        const child = Node{
            .parent = self,
            .children = std.StringHashMap(Node).init(allocator),
            .size = size,
        };
        try self.children.put(name, child);
    }

    pub fn calcRecursiveSize(self: *Node) usize {
        if (self.size != null) {
            return self.size.?;
        }
        std.debug.assert(self.children.count() > 0);
        var size: usize = 0;
        var it = self.children.iterator();
        while (it.next()) |child| {
            size += child.value_ptr.calcRecursiveSize();
        }
        self.size = size;
        return size;
    }
};

fn printNode(allocator: std.mem.Allocator, name: []const u8, node: *const Node, indent: []const u8) anyerror!void {
    std.debug.print("{s}{s}: {}\n", .{ indent, name, node.size orelse 0 });
    const new_ident = try std.fmt.allocPrint(allocator, "{s}  ", .{indent});
    defer allocator.free(new_ident);
    var it = node.children.iterator();
    while (it.next()) |child| {
        try printNode(allocator, child.key_ptr.*, child.value_ptr, new_ident);
    }
}

fn printTree(allocator: std.mem.Allocator, root: *const Node) anyerror!void {
    try printNode(allocator, "/", root, "");
}

fn accumulateRecursiveSizesInner(node: *const Node, max_size: usize, size: *usize) void {
    if (node.size.? <= max_size and node.children.count() != 0) {
        size.* += node.size.?;
    }
    var it = node.children.iterator();
    while (it.next()) |child| {
        accumulateRecursiveSizesInner(child.value_ptr, max_size, size);
    }
}

fn accumulateRecursiveSizes(root: *const Node, max_size: usize) usize {
    var size: usize = 0;
    accumulateRecursiveSizesInner(root, max_size, &size);
    return size;
}

fn createTree(allocator: std.mem.Allocator, buf: []const u8) anyerror!Node {
    var root = Node{
        .children = std.StringHashMap(Node).init(allocator),
    };
    var cur = &root;

    var listing = false;
    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        if (line[0] == '$') {
            listing = false;
            if (line[2] == 'l') {
                listing = true;
            } else {
                std.debug.assert(line[2] == 'c');
                var records = std.mem.tokenize(u8, line, " ");
                _ = records.next();
                _ = records.next();
                const name = records.next().?;
                if (name[0] == '.' and name[1] == '.') {
                    cur = cur.parent.?;
                } else if (name[0] == '/' and name.len == 1) {
                    cur = &root;
                } else {
                    var child = cur.children.getPtr(name);
                    if (child == null) {
                        try cur.addChild(allocator, name, null);
                        cur = cur.children.getPtr(name).?;
                    } else {
                        cur = child.?;
                    }
                }
            }
        } else {
            var records = std.mem.tokenize(u8, line, " ");
            const f1 = records.next().?;
            const name = records.next().?;
            var size: ?usize = null;
            if (f1[0] != 'd') {
                size = try std.fmt.parseInt(usize, f1, 10);
            }
            try cur.addChild(allocator, name, size);
        }
    }

    _ = root.calcRecursiveSize();

    return root;
}

fn solve(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var root = try createTree(allocator, buf);

    // try printTree(allocator, &root);

    const ans = accumulateRecursiveSizes(&root, 100000);

    return ans;
}

fn example1() anyerror!usize {
    return solve("problems/example_07.txt");
}

fn part1() anyerror!usize {
    return solve("problems/problem_07.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 95437), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 1232307), ans);
}
