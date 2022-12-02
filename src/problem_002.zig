const std = @import("std");
const readFileIntoBuf = @import("util.zig").readFileIntoBuf;

const Weapon = enum {
    Rock,
    Paper,
    Scissors,
    pub fn score(self: Weapon) i32 {
        return switch (self) {
            Weapon.Rock => 1,
            Weapon.Paper => 2,
            Weapon.Scissors => 3,
        };
    }
};

const Round = struct {
    p1: Weapon,
    p2: Weapon,
    pub fn score(self: *const Round) i32 {
        const p1 = self.p1;
        const p2 = self.p2;
        const p2_w_score = p2.score();
        switch (p1) {
            Weapon.Rock => {
                switch (p2) {
                    Weapon.Paper => return 6 + p2_w_score,
                    Weapon.Rock => return 3 + p2_w_score,
                    Weapon.Scissors => return p2_w_score,
                }
            },
            Weapon.Paper => {
                switch (p2) {
                    Weapon.Scissors => return 6 + p2_w_score,
                    Weapon.Paper => return 3 + p2_w_score,
                    Weapon.Rock => return p2_w_score,
                }
            },
            Weapon.Scissors => {
                switch (p2) {
                    Weapon.Rock => return 6 + p2_w_score,
                    Weapon.Scissors => return 3 + p2_w_score,
                    Weapon.Paper => return p2_w_score,
                }
            },
        }
    }
};

fn charToWeapon(c: u8) anyerror!Weapon {
    return switch (c) {
        'A', 'X' => Weapon.Rock,
        'B', 'Y' => Weapon.Paper,
        'C', 'Z' => Weapon.Scissors,
        else => unreachable,
    };
}

fn parseInput1(path: []const u8) anyerror!std.ArrayList(Round) {
    const allocator = std.heap.page_allocator;
    const buf = try readFileIntoBuf(allocator, path);
    var lines = std.mem.tokenize(u8, buf, "\n");
    var rounds = std.ArrayList(Round).init(allocator);
    while (lines.next()) |line| {
        var moves = std.mem.tokenize(u8, line, " ");
        const p1 = try charToWeapon(moves.next().?[0]);
        const p2 = try charToWeapon(moves.next().?[0]);
        try rounds.append(Round{ .p1 = p1, .p2 = p2 });
    }
    return rounds;
}

fn getP2Weapon(c: u8, p1: Weapon) anyerror!Weapon {
    return switch (c) {
        'X' => {
            switch (p1) {
                Weapon.Rock => return Weapon.Scissors,
                Weapon.Paper => return Weapon.Rock,
                Weapon.Scissors => return Weapon.Paper,
            }
        },
        'Y' => return p1,
        'Z' => {
            switch (p1) {
                Weapon.Rock => return Weapon.Paper,
                Weapon.Paper => return Weapon.Scissors,
                Weapon.Scissors => return Weapon.Rock,
            }
        },
        else => unreachable,
    };
}

fn parseInput2(path: []const u8) anyerror!std.ArrayList(Round) {
    const allocator = std.heap.page_allocator;
    const buf = try readFileIntoBuf(allocator, path);
    var lines = std.mem.tokenize(u8, buf, "\n");
    var rounds = std.ArrayList(Round).init(allocator);
    while (lines.next()) |line| {
        var moves = std.mem.tokenize(u8, line, " ");
        const p1 = try charToWeapon(moves.next().?[0]);
        const p2 = try getP2Weapon(moves.next().?[0], p1);
        try rounds.append(Round{ .p1 = p1, .p2 = p2 });
    }
    return rounds;
}

fn getTotalScore1(path: []const u8) anyerror!i32 {
    const rounds = try parseInput1(path);
    defer rounds.deinit();
    var sum: i32 = 0;
    for (rounds.items) |round| {
        sum += round.score();
    }
    return sum;
}

fn getTotalScore2(path: []const u8) anyerror!i32 {
    const rounds = try parseInput2(path);
    defer rounds.deinit();
    var sum: i32 = 0;
    for (rounds.items) |round| {
        sum += round.score();
    }
    return sum;
}

fn example1() anyerror!i32 {
    return getTotalScore1("problems/example_002.txt");
}

fn example2() anyerror!i32 {
    return getTotalScore2("problems/example_002.txt");
}

fn part1() anyerror!i32 {
    return getTotalScore1("problems/problem_002.txt");
}

fn part2() anyerror!i32 {
    return getTotalScore2("problems/problem_002.txt");
}

test "example1" {
    const ans = try example1();
    try std.testing.expectEqual(@as(i32, 15), ans);
}

test "part1" {
    const ans = try part1();
    try std.testing.expectEqual(@as(i32, 11475), ans);
}

test "example2" {
    const ans = try example2();
    try std.testing.expectEqual(@as(i32, 12), ans);
}

test "part2" {
    const ans = try part2();
    try std.testing.expectEqual(@as(i32, 16862), ans);
}
