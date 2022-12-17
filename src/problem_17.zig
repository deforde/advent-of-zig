const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Coord = struct {
    x: i32 = 0,
    y: i32 = 0,
};

const Columns = std.ArrayList(std.ArrayList(i32));

const Shape = std.ArrayList(Coord);

const ShapeTy = enum { HORI, PLUS, JAY, VERT, SQR };

fn updateColumns(s: *Shape, cols: *Columns) anyerror!void {
    for (s.items) |c| {
        var col = &cols.items[@intCast(usize, c.x)];
        try col.append(c.y);
        std.sort.sort(i32, col.items, {}, comptime std.sort.asc(i32));
    }
}

fn getColMax(cols: *Columns) i32 {
    var max: i32 = 0;
    for (cols.items) |col| {
        max = std.math.max(max, col.items[col.items.len - 1]);
    }
    return max;
}

fn procMove(m: u8, s: *Shape, cols: *Columns) anyerror!void {
    var ns = try s.clone();

    switch (m) {
        '>' => {
            for (ns.items) |*c| {
                c.x += 1;
            }
        },
        '<' => {
            for (ns.items) |*c| {
                c.x -= 1;
            }
        },
        else => unreachable,
    }

    if (checkCollisions(cols, &ns)) {
        ns.deinit();
        return;
    }

    s.deinit();
    s.* = ns;
}

fn descend(s: *Shape, cols: *Columns) anyerror!bool {
    var ns = try s.clone();

    for (ns.items) |*c| {
        c.y -= 1;
    }

    if (checkCollisions(cols, &ns)) {
        ns.deinit();
        try updateColumns(s, cols);
        return false;
    }

    s.deinit();
    s.* = ns;
    return true;
}

fn checkCollisions(cols: *Columns, s: *Shape) bool {
    for (s.items) |c| {
        if (c.x < 0 or c.x > 6) {
            return true;
        }
        var col = &cols.items[@intCast(usize, c.x)];
        var i: isize = @intCast(isize, col.items.len - 1);
        while (i >= 0) : (i -= 1) {
            if (c.y == col.items[@intCast(usize, i)]) {
                return true;
            }
        }
    }
    return false;
}

fn genShape(allocator: std.mem.Allocator, ty: ShapeTy, cols: *Columns) anyerror!Shape {
    const miny = getColMax(cols) + 4;

    var shape = Shape.init(allocator);

    switch (ty) {
        ShapeTy.HORI => {
            try shape.append(Coord{ .x = 2, .y = miny });
            try shape.append(Coord{ .x = 3, .y = miny });
            try shape.append(Coord{ .x = 4, .y = miny });
            try shape.append(Coord{ .x = 5, .y = miny });
        },
        ShapeTy.PLUS => {
            try shape.append(Coord{ .x = 2, .y = miny + 1 });
            try shape.append(Coord{ .x = 3, .y = miny });
            try shape.append(Coord{ .x = 3, .y = miny + 1 });
            try shape.append(Coord{ .x = 3, .y = miny + 2 });
            try shape.append(Coord{ .x = 4, .y = miny + 1 });
        },
        ShapeTy.JAY => {
            try shape.append(Coord{ .x = 2, .y = miny });
            try shape.append(Coord{ .x = 3, .y = miny });
            try shape.append(Coord{ .x = 4, .y = miny });
            try shape.append(Coord{ .x = 4, .y = miny + 1 });
            try shape.append(Coord{ .x = 4, .y = miny + 2 });
        },
        ShapeTy.VERT => {
            try shape.append(Coord{ .x = 2, .y = miny });
            try shape.append(Coord{ .x = 2, .y = miny + 1 });
            try shape.append(Coord{ .x = 2, .y = miny + 2 });
            try shape.append(Coord{ .x = 2, .y = miny + 3 });
        },
        ShapeTy.SQR => {
            try shape.append(Coord{ .x = 2, .y = miny });
            try shape.append(Coord{ .x = 3, .y = miny });
            try shape.append(Coord{ .x = 2, .y = miny + 1 });
            try shape.append(Coord{ .x = 3, .y = miny + 1 });
        },
    }

    return shape;
}

fn printCols(cols: Columns) void {
    std.debug.print("\n", .{});
    for (cols.items) |c| {
        std.debug.print("{} ", .{c.items[c.items.len - 1]});
    }
    std.debug.print("\n", .{});
}

fn solve(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var shape_tys = [_]ShapeTy{ ShapeTy.HORI, ShapeTy.PLUS, ShapeTy.JAY, ShapeTy.VERT, ShapeTy.SQR };
    var shape_ty_idx: usize = 0;

    var buf_idx: usize = 0;

    var cols = Columns.init(allocator);
    var i: usize = 0;
    while (i < 7) : (i += 1) {
        var col = std.ArrayList(i32).init(allocator);
        try col.append(0);
        try cols.append(col);
    }
    defer {
        for (cols.items) |*col| {
            col.deinit();
        }
        cols.deinit();
    }

    var n: i32 = 0;
    while (n < 2022) : (n += 1) {
        var shape = try genShape(allocator, shape_tys[shape_ty_idx], &cols);
        defer shape.deinit();
        shape_ty_idx += 1;
        shape_ty_idx %= shape_tys.len;

        while (true) {
            const move = buf[buf_idx];
            buf_idx += 1;
            buf_idx %= (buf.len - 1);

            try procMove(move, &shape, &cols);
            if (!try descend(&shape, &cols)) {
                break;
            }
        }

        // printCols(cols);
    }

    var max = getColMax(&cols);

    const ans: usize = @intCast(usize, max);
    return ans;
}

fn example1() anyerror!usize {
    return solve("problems/example_17.txt");
}

fn part1() anyerror!usize {
    return solve("problems/problem_17.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 3068), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 3127), ans);
}
