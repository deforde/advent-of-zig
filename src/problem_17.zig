const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;
const Allocator = @import("allocator.zig").Allocator;

const Coord = struct {
    x: i64 = 0,
    y: i64 = 0,
};

const Columns = std.ArrayList(std.ArrayList(i64));

const Shape = std.ArrayList(Coord);

const ShapeTy = enum { HORI, PLUS, JAY, VERT, SQR };

const State = [9]i64;
const ReconData = struct {
    max: i64,
    min: i64,
    n: usize,
};
const StateMap = std.AutoHashMap(State, ReconData);

fn shiftCols(cols: *Columns, dh: i64, min: i64) void {
    for (cols.items) |*col| {
        for (col.items) |*h| {
            if (h.* >= min) {
                h.* += dh;
            }
        }
    }
}

fn getState(cols: *Columns, shape_ty_idx: usize, buf_idx: usize) State {
    var state: State = undefined;
    for (cols.items) |col, i| {
        state[i] = col.items[col.items.len - 1];
    }
    const min = std.mem.min(i64, state[0..7]);
    for (state[0..7]) |*x| {
        x.* -= min;
    }
    state[7] = @intCast(i64, shape_ty_idx);
    state[8] = @intCast(i64, buf_idx);
    return state;
}

fn updateColumns(s: *Shape, cols: *Columns) !void {
    for (s.items) |c| {
        var col = &cols.items[@intCast(usize, c.x)];
        try col.append(c.y);
        std.sort.sort(i64, col.items, {}, comptime std.sort.asc(i64));
    }
    const min = getColMin(cols);
    for (cols.items) |*col| {
        var idx: usize = col.items.len - 1;
        while (idx > 0) : (idx -= 1) {
            if (col.items[idx] == min) {
                break;
            }
        }
        if (idx != 0) {
            try col.replaceRange(0, col.items.len - idx, col.items[idx..]);
            col.shrinkRetainingCapacity(col.items.len - idx);
        }
    }
}

fn getColMin(cols: *Columns) i64 {
    var min: i64 = std.math.maxInt(i64);
    for (cols.items) |col| {
        min = std.math.min(min, col.items[col.items.len - 1]);
    }
    return min;
}

fn getColMax(cols: *Columns) i64 {
    var max: i64 = 0;
    for (cols.items) |col| {
        max = std.math.max(max, col.items[col.items.len - 1]);
    }
    return max;
}

fn procMove(m: u8, s: *Shape, cols: *Columns) !void {
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

fn descend(s: *Shape, cols: *Columns) !bool {
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
            if (c.y > col.items[@intCast(usize, i)]) {
                break;
            }
        }
    }
    return false;
}

fn genShape(allocator: std.mem.Allocator, ty: ShapeTy, cols: *Columns) !Shape {
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

fn solve(path: []const u8, nshapes: usize) !usize {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var shape_tys = [_]ShapeTy{ ShapeTy.HORI, ShapeTy.PLUS, ShapeTy.JAY, ShapeTy.VERT, ShapeTy.SQR };
    var shape_ty_idx: usize = 0;

    var buf_idx: usize = 0;

    var cols = Columns.init(allocator);
    var i: usize = 0;
    while (i < 7) : (i += 1) {
        var col = std.ArrayList(i64).init(allocator);
        try col.append(0);
        try cols.append(col);
    }
    defer {
        for (cols.items) |*col| {
            col.deinit();
        }
        cols.deinit();
    }

    var state_map = StateMap.init(allocator);
    defer state_map.deinit();
    var cycle_found = false;

    var n: usize = 0;
    while (n < nshapes) : (n += 1) {
        var shape = try genShape(allocator, shape_tys[shape_ty_idx], &cols);
        defer shape.deinit();

        if (!cycle_found) {
            // std.debug.print("checking for pattern...\n", .{});
            var state = getState(&cols, shape_ty_idx, buf_idx);
            var ext_state = state_map.get(state);
            if (ext_state != null) {
                cycle_found = true;
                const recon_data = ext_state.?;
                const dn = n - recon_data.n;
                const ncycles = (nshapes - n) / dn;
                const dh = (getColMax(&cols) - recon_data.max) * @intCast(i64, ncycles);
                // std.debug.print("pattern found: {any}, recon_data = {any}\n", .{ state, recon_data });
                // std.debug.print("dh = {}, dn = {}, ncycles = {}\n", .{ dh, dn, ncycles });
                shiftCols(&cols, dh, recon_data.min);
                n += ncycles * dn;
                shape.deinit();
                shape = try genShape(allocator, shape_tys[shape_ty_idx], &cols);
            } else {
                try state_map.put(state, ReconData{ .max = getColMax(&cols), .min = getColMin(&cols), .n = n });
            }
        }

        while (true) {
            const move = buf[buf_idx];
            buf_idx += 1;
            buf_idx %= (buf.len - 1);

            try procMove(move, &shape, &cols);
            if (!try descend(&shape, &cols)) {
                break;
            }
        }

        shape_ty_idx += 1;
        shape_ty_idx %= shape_tys.len;

        // printCols(cols);
    }

    var max = getColMax(&cols);

    const ans: usize = @intCast(usize, max);
    return ans;
}

fn example1() !usize {
    return solve("problems/example_17.txt", 2022);
}

fn example2() !usize {
    return solve("problems/example_17.txt", 1000000000000);
}

fn part1() !usize {
    return solve("problems/problem_17.txt", 2022);
}

fn part2() !usize {
    return solve("problems/problem_17.txt", 1000000000000);
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 3068), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 1514285714288), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 3127), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 1542941176480), ans);
}
