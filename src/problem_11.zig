const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;
const Allocator = @import("allocator.zig").Allocator;

const Monkey = struct {
    const Op = enum {
        ADD,
        MUL,
        SQR,
    };

    items: std.ArrayList(u64),
    op: Op = Monkey.Op.ADD,
    op_val: ?u64 = null,
    test_quotient: u64 = 1,
    true_target: usize = 0,
    false_target: usize = 0,
    inspect_cnt: usize = 0,

    pub fn deinit(self: *Monkey) void {
        self.items.deinit();
    }
};

fn genMonkeys(allocator: std.mem.Allocator, path: []const u8) !std.ArrayList(Monkey) {
    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var monkeys = std.ArrayList(Monkey).init(allocator);

    var blocks = std.mem.split(u8, buf, "\n\n");
    while (blocks.next()) |block| {
        var monkey = Monkey{
            .items = std.ArrayList(u64).init(allocator),
        };

        var lines = std.mem.tokenize(u8, block, "\n");
        _ = lines.next();

        var starting_items = std.mem.tokenize(u8, lines.next().?[18..], ", ");
        while (starting_items.next()) |item| {
            try monkey.items.insert(0, try std.fmt.parseInt(u64, item, 10));
        }

        var op_tokens = std.mem.tokenize(u8, lines.next().?[19..], " ");
        _ = op_tokens.next();
        var opty = op_tokens.next().?;
        var operand = op_tokens.next().?;
        if (std.mem.eql(u8, operand, "old")) {
            monkey.op = Monkey.Op.SQR;
        } else {
            switch (opty[0]) {
                '*' => monkey.op = Monkey.Op.MUL,
                '+' => monkey.op = Monkey.Op.ADD,
                else => unreachable,
            }
            monkey.op_val = try std.fmt.parseInt(u64, operand, 10);
        }

        monkey.test_quotient = try std.fmt.parseInt(u64, lines.next().?[21..], 10);

        monkey.true_target = try std.fmt.parseInt(usize, lines.next().?[29..], 10);
        monkey.false_target = try std.fmt.parseInt(usize, lines.next().?[30..], 10);

        try monkeys.append(monkey);
    }

    return monkeys;
}

fn simRounds(monkeys: *std.ArrayList(Monkey), nrounds: usize, do_div: bool) !void {
    var super_modulo: u64 = 1;
    var k: usize = 0;
    while (k < monkeys.items.len) : (k += 1) {
        super_modulo *= monkeys.items[k].test_quotient;
    }

    var i: usize = 0;
    while (i < nrounds) : (i += 1) {
        var j: usize = 0;
        while (j < monkeys.items.len) : (j += 1) {
            var monkey = &monkeys.items[j];
            while (monkey.*.items.popOrNull()) |item| {
                monkey.*.inspect_cnt += 1;
                var val = item;
                switch (monkey.*.op) {
                    Monkey.Op.ADD => {
                        val += monkey.*.op_val.?;
                    },
                    Monkey.Op.MUL => {
                        val *= monkey.*.op_val.?;
                    },
                    Monkey.Op.SQR => {
                        val *= val;
                    },
                }
                if (do_div) {
                    val /= 3;
                } else {
                    val %= super_modulo;
                }
                if (val % monkey.*.test_quotient == 0) {
                    try monkeys.items[monkey.*.true_target].items.insert(0, val);
                } else {
                    try monkeys.items[monkey.*.false_target].items.insert(0, val);
                }
            }
        }
    }
}

fn printMonkeys(monkeys: *std.ArrayList(Monkey)) void {
    std.debug.print("\n", .{});
    for (monkeys.*.items) |monkey, i| {
        std.debug.print("Monkey {} ({}): ", .{ i, monkey.inspect_cnt });
        for (monkey.items.items) |item| {
            std.debug.print("{} ", .{item});
        }
        std.debug.print("\n", .{});
    }
}

fn solve(path: []const u8, nrounds: usize, do_div: bool) !usize {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    var monkeys = try genMonkeys(allocator, path);
    defer {
        var i: usize = 0;
        while (i < monkeys.items.len) : (i += 1) {
            monkeys.items[i].deinit();
        }
        monkeys.deinit();
    }

    try simRounds(&monkeys, nrounds, do_div);

    // printMonkeys(&monkeys);

    var inspect_cnts = std.ArrayList(usize).init(allocator);
    defer inspect_cnts.deinit();
    for (monkeys.items) |monkey| {
        try inspect_cnts.append(monkey.inspect_cnt);
    }
    std.sort.sort(usize, inspect_cnts.items, {}, comptime std.sort.desc(usize));

    const ans: usize = inspect_cnts.items[0] * inspect_cnts.items[1];
    return ans;
}

fn example1() !usize {
    return solve("problems/example_11.txt", 20, true);
}

fn example2() !usize {
    return solve("problems/example_11.txt", 10000, false);
}

fn part1() !usize {
    return solve("problems/problem_11.txt", 20, true);
}

fn part2() !usize {
    return solve("problems/problem_11.txt", 10000, false);
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 10605), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(usize, 2713310158), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 102399), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(usize, 23641658401), ans);
}
