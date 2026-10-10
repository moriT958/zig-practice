//! 第 2 章: 変数・型・制御構文
//!
//! 実行: zig test learn/02_basics.zig
//! このファイルは `test` ブロックで動作を確認します。
//! 値を変えて、テストが失敗するのを試してみましょう。

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "const と var" {
    const a = 10; // 変更不可。基本は const を使う
    var b: i32 = 20; // 変更可能。型を指定
    b += a;
    try expectEqual(30, b);

    // 未使用の変数・ローカル const はコンパイルエラーになる。
    // 意図的に使わないときは `_ = x;` と書く。
}

test "整数・浮動小数点・bool" {
    const x: u8 = 255;
    // オーバーフローは Debug では panic。ラップさせたいときは専用演算子 +% を使う
    try expectEqual(0, x +% 1);

    const y: f64 = 1.5;
    try expectEqual(3.0, y * 2);

    const flag: bool = x > 100 and y < 2;
    try expect(flag);

    // 型変換は明示的に。@as, @intCast, @floatFromInt などを使う
    const big: i64 = 1000;
    const small: i16 = @intCast(big);
    try expectEqual(1000, small);
}

test "配列とスライス" {
    const arr = [_]i32{ 1, 2, 3, 4, 5 }; // 長さはコンパイル時に決まる
    try expectEqual(5, arr.len);

    const slice: []const i32 = arr[1..4]; // 部分列(ポインタ + 長さ)
    try expectEqual(3, slice.len);
    try expectEqual(2, slice[0]);

    // 文字列は []const u8 (UTF-8 のバイト列)。"日本語" は 1 文字 3 バイト
    const s = "日本語";
    try expectEqual(9, s.len);
}

test "if / while / for" {
    // if は式。値を返せる
    const n = 7;
    const kind = if (n % 2 == 0) "偶数" else "奇数";
    try expectEqualStrings("奇数", kind);

    // while: 継続式 (: (i += 1)) を持てる
    var i: u32 = 0;
    var sum: u32 = 0;
    while (i < 5) : (i += 1) {
        sum += i;
    }
    try expectEqual(10, sum);

    // for: 要素と添字を同時に回す
    const items = [_]u32{ 10, 20, 30 };
    var total: u32 = 0;
    for (items, 0..) |item, idx| {
        total += item * @as(u32, @intCast(idx));
    }
    try expectEqual(80, total); // 0*10 + 1*20 + 2*30

    // 範囲のみ: 0..3 は 0,1,2
    var count: usize = 0;
    for (0..3) |_| count += 1;
    try expectEqual(3, count);
}

test "switch は網羅性が必須" {
    const score: u8 = 85;
    const grade = switch (score) {
        90...100 => 'A',
        80...89 => 'B',
        70...79 => 'C',
        else => 'D', // 全ての値を網羅しないとコンパイルエラー
    };
    try expectEqual('B', grade);
}

test "ラベル付きブロックと break" {
    const v = blk: {
        var acc: u32 = 1;
        for (1..5) |k| acc *= @intCast(k);
        break :blk acc;
    };
    try expectEqual(24, v);
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "関数" {
    try expectEqual(5, add(2, 3));
}
