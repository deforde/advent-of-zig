const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

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

fn genMonkeys(allocator: std.mem.Allocator, path: []const u8) anyerror!std.ArrayList(Monkey) {
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

fn simRounds(monkeys: *std.ArrayList(Monkey), nrounds: usize) anyerror!void {
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
                val /= 3;
                if (@mod(val, monkey.*.test_quotient) == 0) {
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

fn solve(path: []const u8) anyerror!usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var monkeys = try genMonkeys(allocator, path);
    defer {
        var i: usize = 0;
        while (i < monkeys.items.len) : (i += 1) {
            monkeys.items[i].deinit();
        }
        monkeys.deinit();
    }

    try simRounds(&monkeys, 20);

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

fn example1() anyerror!usize {
    return solve("problems/example_11.txt");
}

fn part1() anyerror!usize {
    return solve("problems/problem_11.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 10605), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 102399), ans);
}
