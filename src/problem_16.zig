const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Node = struct {
    flow_rate: i64,
    connections: std.ArrayList(i64),
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

fn solve(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var map = try genNodeMap(allocator, path);
    defer {
        var it = map.iterator();
        while (it.next()) |node| {
            node.value_ptr.connections.deinit();
        }
        map.deinit();
    }

    printNodeMap(&map);

    const ans: usize = 0;
    return ans;
}

fn example1() anyerror!usize {
    return solve("problems/example_16.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 0), ans);
}
