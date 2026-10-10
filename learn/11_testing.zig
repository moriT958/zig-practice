//! 第 11 章(基本文法編): テスト
//!
//! 実行: zig test learn/11_testing.zig
//!
//! `test "名前" { ... }` はテスト用ビルドのときだけコンパイル・実行されます。
//! 本体のコードと同じファイルに書くのが Zig の流儀です。

const std = @import("std");
const testing = std.testing;

fn clamp(x: i32, lo: i32, hi: i32) i32 {
    return @max(lo, @min(x, hi));
}

test "expectEqual: 期待値が左" {
    // 第 1 引数が期待値、第 2 引数が実際の値
    try testing.expectEqual(5, clamp(5, 0, 10));
    try testing.expectEqual(0, clamp(-3, 0, 10));
    try testing.expectEqual(10, clamp(99, 0, 10));
}

test "いろいろな expect" {
    try testing.expect(1 + 1 == 2);
    try testing.expectEqualStrings("abc", "abc");
    try testing.expectEqualSlices(u8, &.{ 1, 2 }, &.{ 1, 2 });
    try testing.expectApproxEqAbs(@as(f64, 0.3), 0.1 + 0.2, 1e-9);
    try testing.expectError(error.Boom, fails());
}

fn fails() !void {
    return error.Boom;
}

test "メモリリークの検出" {
    // testing.allocator は解放漏れをテスト失敗として報告する
    const gpa = testing.allocator;
    const buf = try gpa.alloc(u8, 8);
    defer gpa.free(buf);
}

test "テスト内ではエラーを try で伝播できる" {
    // テストが error を返せば失敗扱いになる
    const v = try std.fmt.parseInt(i32, "42", 10);
    try testing.expectEqual(42, v);
}

const Stack = struct {
    items: [4]i32 = undefined,
    len: usize = 0,

    fn push(self: *Stack, v: i32) !void {
        if (self.len == self.items.len) return error.Full;
        self.items[self.len] = v;
        self.len += 1;
    }

    fn pop(self: *Stack) ?i32 {
        if (self.len == 0) return null;
        self.len -= 1;
        return self.items[self.len];
    }
};

test "Stack: 正常系" {
    var s: Stack = .{};
    try s.push(1);
    try s.push(2);
    try testing.expectEqual(2, s.pop());
    try testing.expectEqual(1, s.pop());
    try testing.expectEqual(null, s.pop());
}

test "Stack: 満杯でエラー" {
    var s: Stack = .{};
    for (0..4) |i| try s.push(@intCast(i));
    try testing.expectError(error.Full, s.push(99));
}

// コンパイル時の検査: 条件が偽ならコンパイルエラー
comptime {
    std.debug.assert(@sizeOf(u32) == 4);
}

test "テストを選んで実行する" {
    // zig test learn/11_testing.zig --test-filter "Stack"
    // のように、名前に部分一致するテストだけを走らせられる
    try testing.expect(true);
}

// プロジェクトでは `zig build test` で実行する(build.zig の test step)。
// `zig build test --summary all` で件数も表示できる。
