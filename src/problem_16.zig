const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Node = struct {
    flow_rate: i64,
    connections: std.ArrayList(i64),
};

const PathTip = struct {
    id: i64,
    dist: i64,
};

const Path = struct {
    nodes: std.ArrayList(i64),
    press: i64,
};

const NodeMap = std.AutoHashMap(i64, Node);
const NodeDistMap = std.AutoHashMap(i64, std.AutoHashMap(i64, i64));

fn nodeNameToId(nm: *const [2]u8) i64 {
    return @intCast(i64, nm[0] - 'A' + 1) * 26 + nm[1] - 'A';
}

fn nodeIdToName(id: i64) [2]u8 {
    return [2]u8{ 'A' + @intCast(u8, @divTrunc(id, 26)) - 1, 'A' + @intCast(u8, @mod(id, 26)) };
}

fn printNodeMap(map: *NodeMap) void {
    std.debug.print("\n", .{});
    var it = map.iterator();
    while (it.next()) |node| {
        std.debug.print("{s}: {}, [ ", .{ nodeIdToName(node.key_ptr.*), node.value_ptr.flow_rate });
        for (node.value_ptr.connections.items) |*conn| {
            std.debug.print("{s} ", .{nodeIdToName(conn.*)});
        }
        std.debug.print("]\n", .{});
    }
}

fn genNodeMap(allocator: std.mem.Allocator, path: []const u8) anyerror!NodeMap {
    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var map = NodeMap.init(allocator);

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var records = std.mem.tokenize(u8, line, " =;,");
        _ = records.next().?;
        const id = nodeNameToId(records.next().?[0..2]);
        _ = records.next().?;
        _ = records.next().?;
        _ = records.next().?;
        const flow_rate = try std.fmt.parseInt(i64, records.next().?, 10);
        _ = records.next().?;
        _ = records.next().?;
        _ = records.next().?;
        _ = records.next().?;
        var connections = std.ArrayList(i64).init(allocator);
        while (records.next()) |conn| {
            try connections.append(nodeNameToId(conn[0..2]));
        }

        try map.put(id, Node{ .flow_rate = flow_rate, .connections = connections });
    }

    return map;
}

fn isContained(l: *std.ArrayList(i64), id: i64) bool {
    for (l.items) |vn| {
        if (vn == id) {
            return true;
        }
    }
    return false;
}

fn genNodeDistMapInner(dmap: *NodeDistMap, map: *NodeMap, visited: *std.ArrayList(i64), src: i64, path_tips: *std.ArrayList(PathTip)) anyerror!void {
    while (path_tips.popOrNull()) |pt| {
        const curn = map.get(pt.id).?;
        for (curn.connections.items) |n| {
            if (isContained(visited, n)) {
                continue;
            }
            try visited.append(n);
            try dmap.getPtr(src).?.put(n, pt.dist + 1);
            // std.debug.print("  {s} {}\n", .{ nodeIdToName(n), pt.dist + 1 });
            try path_tips.insert(0, PathTip{ .id = n, .dist = pt.dist + 1 });
        }
    }
}

fn genNodeDistMap(allocator: std.mem.Allocator, map: *NodeMap) anyerror!NodeDistMap {
    var dist_map = NodeDistMap.init(allocator);

    var it = map.iterator();
    while (it.next()) |node| {
        try dist_map.put(node.key_ptr.*, std.AutoHashMap(i64, i64).init(allocator));
    }

    it = map.iterator();
    while (it.next()) |node| {
        var visited = std.ArrayList(i64).init(allocator);
        defer visited.deinit();
        try visited.append(node.key_ptr.*);

        var path_tips = std.ArrayList(PathTip).init(allocator);
        defer path_tips.deinit();
        try path_tips.append(PathTip{ .id = node.key_ptr.*, .dist = 0 });

        // std.debug.print("Getting all distances for {s}\n", .{nodeIdToName(node.key_ptr.*)});
        try genNodeDistMapInner(&dist_map, map, &visited, node.key_ptr.*, &path_tips);
    }

    return dist_map;
}

fn printDistMap(dist_map: *NodeDistMap) void {
    var it = dist_map.iterator();
    while (it.next()) |node| {
        std.debug.print("{s}:\n", .{nodeIdToName(node.key_ptr.*)});
        var itt = node.value_ptr.iterator();
        while (itt.next()) |inner_node| {
            std.debug.print("  {s}, {}\n", .{ nodeIdToName(inner_node.key_ptr.*), inner_node.value_ptr.* });
        }
    }
}

fn getMaxPressPathInner(map: *NodeMap, dist_map: *NodeDistMap, dst_nodes: *std.ArrayList(i64), src: i64, p: i64, mins_remaining: i64, path: *std.ArrayList(i64), paths: ?*std.ArrayList(Path)) anyerror!i64 {
    var max_p: i64 = p;
    for (dst_nodes.items) |dst, i| {
        var dup = try dst_nodes.clone();
        defer dup.deinit();
        _ = dup.swapRemove(i);

        const dist = dist_map.get(src).?.get(dst).?;
        var nmr = mins_remaining - dist - 1;
        if (nmr < 1) {
            continue;
        }

        var np = p + map.get(dst).?.flow_rate * nmr;

        var npath = try path.clone();
        defer npath.deinit();
        try npath.append(dst);
        if (paths != null) {
            try updatePath(paths.?, &npath, np);
        }

        var nmp = try getMaxPressPathInner(map, dist_map, &dup, dst, np, nmr, &npath, paths);
        max_p = std.math.max(nmp, max_p);
    }
    return max_p;
}

fn arePathsUnique(p1: *std.ArrayList(i64), p2: *std.ArrayList(i64)) bool {
    for (p1.items[1..]) |x| {
        for (p2.items[1..]) |y| {
            if (x == y) {
                return false;
            }
        }
    }
    return true;
}

fn updatePath(paths: *std.ArrayList(Path), npath: *std.ArrayList(i64), press: i64) anyerror!void {
    for (paths.items) |*path| {
        var path_match = true;
        if (path.nodes.items.len != npath.items.len) {
            path_match = false;
        } else {
            for (npath.items) |node| {
                if (!isContained(&path.nodes, node)) {
                    path_match = false;
                    break;
                }
            }
        }
        if (path_match) {
            if (press > path.press) {
                path.press = press;
            }
            return;
        }
    }
    try paths.append(Path{ .nodes = try npath.clone(), .press = press });
}

fn getMaxPressPath(allocator: std.mem.Allocator, map: *NodeMap, dist_map: *NodeDistMap, dst_nodes: *std.ArrayList(i64), paths: ?*std.ArrayList(Path), maxt: i64) anyerror!i64 {
    var path = std.ArrayList(i64).init(allocator);
    defer path.deinit();
    try path.append(nodeNameToId("AA"));
    return getMaxPressPathInner(map, dist_map, dst_nodes, nodeNameToId("AA"), 0, maxt, &path, paths);
}

fn solve1(path: []const u8) anyerror!usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = try genNodeMap(allocator, path);
    defer {
        var it = map.iterator();
        while (it.next()) |node| {
            node.value_ptr.connections.deinit();
        }
        map.deinit();
    }

    var non_zero_fr = std.ArrayList(i64).init(allocator);
    defer non_zero_fr.deinit();
    {
        var it = map.iterator();
        while (it.next()) |node| {
            if (node.value_ptr.flow_rate != 0) {
                try non_zero_fr.append(node.key_ptr.*);
            }
        }
    }

    var dist_map = try genNodeDistMap(allocator, &map);
    defer {
        var it = dist_map.iterator();
        while (it.next()) |node| {
            node.value_ptr.deinit();
        }
        dist_map.deinit();
    }

    var p = try getMaxPressPath(allocator, &map, &dist_map, &non_zero_fr, null, 30);

    const ans: usize = @intCast(usize, p);
    return ans;
}

fn solve2(path: []const u8) anyerror!usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = try genNodeMap(allocator, path);
    defer {
        var it = map.iterator();
        while (it.next()) |node| {
            node.value_ptr.connections.deinit();
        }
        map.deinit();
    }

    var non_zero_fr = std.ArrayList(i64).init(allocator);
    defer non_zero_fr.deinit();
    {
        var it = map.iterator();
        while (it.next()) |node| {
            if (node.value_ptr.flow_rate != 0) {
                try non_zero_fr.append(node.key_ptr.*);
            }
        }
    }

    var dist_map = try genNodeDistMap(allocator, &map);
    defer {
        var it = dist_map.iterator();
        while (it.next()) |node| {
            node.value_ptr.deinit();
        }
        dist_map.deinit();
    }

    var paths = std.ArrayList(Path).init(allocator);
    defer {
        for (paths.items) |*p| {
            p.nodes.deinit();
        }
        paths.deinit();
    }
    _ = try getMaxPressPath(allocator, &map, &dist_map, &non_zero_fr, &paths, 26);

    var max_press: i64 = 0;
    var i: usize = 0;
    while (i < paths.items.len - 1) : (i += 1) {
        var j: usize = 1;
        while (j < paths.items.len) : (j += 1) {
            var pt1 = &paths.items[i];
            var pt2 = &paths.items[j];
            if (arePathsUnique(&pt1.nodes, &pt2.nodes)) {
                const press = pt1.press + pt2.press;
                max_press = std.math.max(max_press, press);
            }
        }
    }

    const ans: usize = @intCast(usize, max_press);
    return ans;
}

fn example1() anyerror!usize {
    return solve1("problems/example_16.txt");
}

fn example2() anyerror!usize {
    return solve2("problems/example_16.txt");
}

fn part1() anyerror!usize {
    return solve1("problems/problem_16.txt");
}

fn part2() anyerror!usize {
    return solve2("problems/problem_16.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 1651), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 1707), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 1659), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 2382), ans);
}
