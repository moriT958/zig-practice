//! 第 12 章(基本文法編): 制御構文の発展
//!
//! 実行: zig test learn/12_control_flow.zig
//!
//! 第 2・3・5 章で扱った構文の応用編です。Zig は「値を取り出しながら分岐する」
//! 書き方(キャプチャ)が一貫しています。

const std = @import("std");
const testing = std.testing;
const expectEqual = testing.expectEqual;

test "if でキャプチャ: optional / error union" {
    const maybe: ?i32 = 5;
    if (maybe) |v| {
        try expectEqual(5, v);
    } else {
        return error.TestUnexpectedResult;
    }

    const r: anyerror!i32 = 7;
    if (r) |v| {
        try expectEqual(7, v);
    } else |err| {
        return err;
    }
}

test "while でキャプチャ: null になるまで繰り返す" {
    var it = std.mem.splitScalar(u8, "x y z", ' ');
    var n: usize = 0;
    while (it.next()) |_| n += 1;
    try expectEqual(3, n);
}

test "switch の発展: 範囲・複数値・式" {
    const x: u8 = 'k';
    const kind = switch (x) {
        'a'...'z' => "小文字",
        'A'...'Z' => "大文字",
        '0'...'9' => "数字",
        ' ', '\t', '\n' => "空白",
        else => "その他",
    };
    try testing.expectEqualStrings("小文字", kind);
}

const Token = union(enum) {
    number: i32,
    plus,
    minus,
    ident: []const u8,
};

test "switch で union の中身を取り出す" {
    const tokens = [_]Token{ .{ .number = 3 }, .plus, .{ .ident = "x" } };
    var nums: i32 = 0;
    var others: u32 = 0;
    for (tokens) |t| {
        switch (t) {
            .number => |n| nums += n,
            .plus, .minus => others += 1,
            .ident => |name| others += @intCast(name.len),
        }
    }
    try expectEqual(3, nums);
    try expectEqual(2, others);
}

test "switch でポインタキャプチャ(中身を書き換える)" {
    var t: Token = .{ .number = 1 };
    switch (t) {
        .number => |*n| n.* += 10,
        else => {},
    }
    try expectEqual(11, t.number);
}

test "inline for / comptime での繰り返し" {
    // inline for はコンパイル時に展開される。型の異なる要素も回せる
    const values = .{ @as(u8, 1), @as(i32, -2), @as(f32, 0.5) };
    var count: usize = 0;
    inline for (values) |v| {
        _ = v;
        count += 1;
    }
    try expectEqual(3, count);
}

test "複数のスライスを同時に回す" {
    const a = [_]i32{ 1, 2, 3 };
    const b = [_]i32{ 10, 20, 30 };
    var dot: i32 = 0;
    for (a, b) |x, y| dot += x * y; // 長さが違うと panic
    try expectEqual(140, dot);
}

test "ラベル付き break / continue" {
    var found: ?struct { usize, usize } = null;
    outer: for (0..5) |i| {
        for (0..5) |j| {
            if (i * j == 6) {
                found = .{ i, j };
                break :outer; // 外側のループまで抜ける
            }
            if (j > i) continue :outer;
        }
    }
    try expectEqual(2, found.?[0]);
    try expectEqual(3, found.?[1]);
}

test "else 付きの for / while は式として値を返せる" {
    const items = [_]i32{ 1, 3, 5 };
    const first_even: ?i32 = for (items) |v| {
        if (@mod(v, 2) == 0) break v;
    } else null;
    try expectEqual(null, first_even);
}

test "unreachable と @panic" {
    // 「ここには来ない」と表明する。Debug では到達すると panic
    const x: u8 = 3;
    const r = switch (x) {
        0...5 => "small",
        else => unreachable,
    };
    try testing.expectEqualStrings("small", r);
}
