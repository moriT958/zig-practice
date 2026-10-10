//! 第 8 章(基本文法編): ポインタ
//!
//! 実行: zig test learn/08_pointers.zig
//!
//! Zig のポインタは種類ごとに型が分かれています。
//!   *T         単一要素へのポインタ(演算不可)
//!   [*]T       複数要素へのポインタ(長さ不明、Cの配列ポインタ相当)
//!   []T        スライス(ポインタ + 長さ)。普段はこれを使う
//!   *const T   読み取り専用
//!   ?*T        null になりうるポインタ

const std = @import("std");
const testing = std.testing;
const expectEqual = testing.expectEqual;

test "単一要素ポインタ" {
    var x: i32 = 10;
    const p: *i32 = &x; // & でアドレスを取る
    p.* = 20; // .* で参照先へアクセス
    try expectEqual(20, x);
}

fn increment(n: *u32) void {
    n.* += 1;
}

test "参照渡し" {
    // 引数は常に値渡し。変更させたいときはポインタを渡す
    var count: u32 = 0;
    increment(&count);
    increment(&count);
    try expectEqual(2, count);
}

test "const ポインタ" {
    const x: i32 = 5;
    const p: *const i32 = &x;
    try expectEqual(5, p.*);
    // p.* = 6; // コンパイルエラー: const への書き込み
}

test "配列へのポインタとスライス" {
    var arr = [_]u8{ 1, 2, 3, 4 };

    // 配列へのポインタ(*[4]u8)はスライスに自動で変換される
    const slice: []u8 = &arr;
    slice[0] = 100;
    try expectEqual(100, arr[0]);

    // スライスの一部を取る
    const mid = arr[1..3];
    try expectEqual(2, mid.len);
    try expectEqual(@as(usize, 4), arr.len);

    // スライスの要素のポインタ
    const first: *u8 = &slice[0];
    first.* = 7;
    try expectEqual(7, arr[0]);
}

fn fill(buf: []u8, value: u8) void {
    // スライスは参照の一種。要素の書き換えは呼び出し元にも見える
    for (buf) |*b| b.* = value; // |*b| で要素のポインタを受け取る
}

test "for で要素を書き換える" {
    var arr = [_]u8{ 0, 0, 0 };
    fill(&arr, 9);
    try testing.expectEqualSlices(u8, &.{ 9, 9, 9 }, &arr);
}

test "optional ポインタ" {
    var value: i32 = 1;
    var maybe: ?*i32 = null;
    try expectEqual(null, maybe);

    maybe = &value;
    if (maybe) |p| p.* += 1;
    try expectEqual(2, value);
    // ?*T は null を表現でき、C のように「うっかり null」にならない。
    // *T は null になれない。
}

const Node = struct {
    value: i32,
    next: ?*Node = null,
};

test "連結リスト(ポインタの実用例)" {
    var c: Node = .{ .value = 3 };
    var b: Node = .{ .value = 2, .next = &c };
    var a: Node = .{ .value = 1, .next = &b };
    _ = .{ &a, &b, &c };

    var sum: i32 = 0;
    var cur: ?*Node = &a;
    while (cur) |node| : (cur = node.next) {
        sum += node.value;
    }
    try expectEqual(6, sum);
}

test "ポインタキャストは明示的に" {
    var x: u32 = 0x01020304;
    const bytes: *[4]u8 = @ptrCast(&x);
    // ネイティブのエンディアンに依存する。確認するだけで値は固定しない
    try expectEqual(4, bytes.len);
}
