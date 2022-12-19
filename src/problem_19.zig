const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Material = enum {
    ORE,
    CLY,
    OBS,
    GEO,
    fn fromString(s: []const u8) Material {
        if (std.mem.eql(u8, s, "ore")) {
            return Material.ORE;
        }
        if (std.mem.eql(u8, s, "clay")) {
            return Material.CLY;
        }
        if (std.mem.eql(u8, s, "obsidian")) {
            return Material.OBS;
        }
        if (std.mem.eql(u8, s, "geode")) {
            return Material.GEO;
        }
        unreachable;
    }
};

const BotArr = [4]u32;
const MatArr = BotArr;

const BluePrint = [4]MatArr;

const State = struct {
    bots: BotArr = BotArr{ 1, 0, 0, 0 },
    mat: MatArr = MatArr{ 0, 0, 0, 0 },
    viable: BotArr = BotArr{ 1, 1, 1, 1 },
};

fn getBlueprints(allocator: std.mem.Allocator, path: []const u8) anyerror!std.ArrayList(BluePrint) {
    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var bps = std.ArrayList(BluePrint).init(allocator);

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var records = std.mem.tokenize(u8, line, ":.");
        _ = records.next().?;

        var bp = std.mem.zeroes(BluePrint);

        while (records.next()) |record| {
            var elems = std.mem.tokenize(u8, record, " ");
            _ = elems.next().?;
            const bot = Material.fromString(elems.next().?);
            _ = elems.next().?;
            while (elems.next() != null) {
                const quant = try std.fmt.parseInt(u32, elems.next().?, 10);
                const mat = Material.fromString(elems.next().?);
                bp[@enumToInt(bot)][@enumToInt(mat)] = quant;
            }
        }

        try bps.append(bp);
    }

    return bps;
}

fn collectMats(state: *State) void {
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        state.mat[i] += state.bots[i];
    }
}

fn getPeakCosts(bp: BluePrint) MatArr {
    var costs = MatArr{ 0, 0, 0, 0 };
    var bot: usize = 0;
    while (bot < 4) : (bot += 1) {
        var mat: usize = 0;
        while (mat < 4) : (mat += 1) {
            costs[mat] = std.math.max(costs[mat], bp[bot][mat]);
        }
    }
    return costs;
}

fn isAffordable(state: *State, costs: MatArr) bool {
    var mat: usize = 0;
    while (mat < 4) : (mat += 1) {
        if (state.mat[mat] < costs[mat]) {
            return false;
        }
    }
    return true;
}

fn tryBuildGeoBot(state: *State, bp: BluePrint) bool {
    const geo_idx = @enumToInt(Material.GEO);
    const costs = bp[geo_idx];
    if (isAffordable(state, costs)) {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            state.mat[i] -= costs[i];
        }
        collectMats(state);
        state.bots[geo_idx] += 1;
        return true;
    }
    return false;
}

fn branchState(allocator: std.mem.Allocator, state: *State, bp: BluePrint, pc: MatArr) anyerror!std.ArrayList(State) {
    var nstates = std.ArrayList(State).init(allocator);

    var bot: usize = 0;
    while (bot < 3) : (bot += 1) {
        if (state.bots[bot] < pc[bot] and state.viable[bot] == 1) {
            const costs = bp[bot];
            if (isAffordable(state, costs)) {
                state.viable[bot] = 0;
                var nstate = state.*;
                nstate.viable = BotArr{ 1, 1, 1, 1 };
                var i: usize = 0;
                while (i < 4) : (i += 1) {
                    nstate.mat[i] -= costs[i];
                }
                collectMats(&nstate);
                nstate.bots[bot] += 1;
                try nstates.append(nstate);
            }
        }
    }

    return nstates;
}

fn pruneStates(states: *std.ArrayList(State), mr: u32) void {
    const geo_idx: usize = @enumToInt(Material.GEO);

    var max_geo: u32 = 0;
    for (states.items) |state| {
        var this_max_geo = state.mat[geo_idx] + state.bots[geo_idx] * mr;
        max_geo = std.math.max(max_geo, this_max_geo);
    }

    var i: usize = 0;
    while (i < states.items.len) {
        var this_max_geo = states.items[i].mat[geo_idx] + states.items[i].bots[geo_idx] * mr;
        var m: u32 = 0;
        while (m < mr) : (m += 1) {
            this_max_geo += (m + 1);
        }
        if (this_max_geo < max_geo) {
            _ = states.swapRemove(i);
            continue;
        }
        i += 1;
    }
}

fn runBlueprint(allocator: std.mem.Allocator, bp: BluePrint, mins: u32) anyerror!u32 {
    var states = std.ArrayList(State).init(allocator);
    defer states.deinit();
    try states.append(State{});

    const peak_costs = getPeakCosts(bp);

    var m: u32 = 0;
    while (m < mins) : (m += 1) {
        var nstates = std.ArrayList(State).init(allocator);
        defer nstates.deinit();
        for (states.items) |*state| {
            if (!tryBuildGeoBot(state, bp)) {
                var tmp = try branchState(allocator, state, bp, peak_costs);
                defer tmp.deinit();
                try nstates.appendSlice(tmp.items);
                collectMats(state);
            }
        }
        try states.appendSlice(nstates.items);
        pruneStates(&states, mins - m);
        // std.debug.print("\n\n{any}\n\n", .{states.items});
    }

    var max_geo: u32 = 0;
    for (states.items) |state| {
        max_geo = std.math.max(max_geo, state.mat[@enumToInt(Material.GEO)]);
    }
    // std.debug.print("\n{}\n", .{max_geo});
    return max_geo;
}

fn solve1(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var bps = try getBlueprints(allocator, path);
    defer bps.deinit();
    // std.debug.print("\n{any}\n", .{bps.items});

    var sum: usize = 0;
    for (bps.items) |bp, i| {
        sum += (i + 1) * try runBlueprint(allocator, bp, 24);
    }
    return sum;
}

fn solve2(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var bps = try getBlueprints(allocator, path);
    defer bps.deinit();
    while (bps.items.len > 3) : (_ = bps.pop()) {}
    // std.debug.print("\n{any}\n", .{bps.items});

    var prod: usize = 1;
    for (bps.items) |bp| {
        prod *= try runBlueprint(allocator, bp, 32);
    }
    return prod;
}

fn example1() anyerror!usize {
    return solve1("problems/example_19.txt");
}

fn example2() anyerror!usize {
    return solve2("problems/example_19.txt");
}

fn part1() anyerror!usize {
    return solve1("problems/problem_19.txt");
}

fn part2() anyerror!usize {
    return solve2("problems/problem_19.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 33), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 3472), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 1349), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 21840), ans);
}
