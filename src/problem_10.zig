const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Op = enum {
    NOOP,
    ADD,

    pub fn fromString(s: []const u8) Op {
        if (std.mem.eql(u8, s, "addx")) {
            return Op.ADD;
        } else if (std.mem.eql(u8, s, "noop")) {
            return Op.NOOP;
        }
        unreachable;
    }
};

const VM = struct {
    x: i32 = 1,
    cycle: i32 = 0,
    sig_strength_sum: usize = 0,
    crt_line: [40]u8 = [40]u8{ '#', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.', '.' },

    pub fn incCycle(self: *VM) void {
        self.cycle += 1;
        if (@mod((self.cycle + 1) - 20, 40) == 0) {
            self.sig_strength_sum += @intCast(usize, (self.cycle + 1) * self.x);
        }
        const idx: usize = @intCast(usize, @mod(self.cycle, 40));
        self.crt_line[idx] = if (idx >= (self.x - 1) and idx <= (self.x + 1)) '#' else '.';
        if (idx == 39) {
            std.debug.print("{s}\n", .{self.crt_line});
        }
    }

    pub fn exec(self: *VM, op: Op, val: ?i32) void {
        switch (op) {
            Op.NOOP => {
                self.incCycle();
            },
            Op.ADD => {
                self.incCycle();
                self.x += val.?;
                self.incCycle();
            },
        }
    }
};

fn solve(path: []const u8) !usize {
    var arena = Allocator.init();
    defer arena.deinit();
    const allocator = arena.allocator();

    const buf = try readFileIntoBuf(allocator, path);
    defer allocator.free(buf);

    var vm = VM{};
    std.debug.print("\n", .{});

    var lines = std.mem.tokenize(u8, buf, "\n");
    while (lines.next()) |line| {
        var records = std.mem.tokenize(u8, line, " ");
        const op = Op.fromString(records.next().?);
        var val: ?i32 = null;
        if (op == Op.ADD) {
            val = try std.fmt.parseInt(i32, records.next().?, 10);
        }
        vm.exec(op, val);
    }

    return vm.sig_strength_sum;
}

fn example1() !usize {
    return solve("problems/example_10.txt");
}

fn part1() !usize {
    return solve("problems/problem_10.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(usize, 13140), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(usize, 12880), ans);
}
