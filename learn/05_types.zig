//! 第 5 章: 構造体・enum・union・comptime
//!
//! 実行: zig test learn/05_types.zig

const std = @import("std");
const testing = std.testing;
const expectEqual = testing.expectEqual;

// ---- struct ----
const Point = struct {
    x: f32,
    y: f32 = 0, // デフォルト値

    // 構造体の中の関数 = メソッド。第 1 引数が self なら `p.length()` で呼べる
    fn length(self: Point) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }

    fn scale(self: *Point, k: f32) void {
        self.x *= k;
        self.y *= k;
    }
};

test "struct" {
    var p: Point = .{ .x = 3, .y = 4 }; // 型は左辺から推論される
    try expectEqual(5, p.length());
    p.scale(2);
    try expectEqual(10, p.length());

    const q: Point = .{ .x = 1 };
    try expectEqual(0, q.y);
}

// ---- enum ----
const Color = enum {
    red,
    green,
    blue,

    fn isWarm(self: Color) bool {
        return self == .red;
    }
};

test "enum" {
    const c: Color = .red;
    try testing.expect(c.isWarm());
    try testing.expectEqualStrings("blue", @tagName(Color.blue));
}

// ---- tagged union ----
const Shape = union(enum) {
    circle: f32, // 半径
    rect: struct { w: f32, h: f32 },

    fn area(self: Shape) f32 {
        return switch (self) {
            .circle => |r| std.math.pi * r * r,
            .rect => |r| r.w * r.h,
        };
    }
};

test "tagged union" {
    const s: Shape = .{ .rect = .{ .w = 2, .h = 3 } };
    try expectEqual(6, s.area());
    const c: Shape = .{ .circle = 1 };
    try testing.expectApproxEqAbs(3.14159, c.area(), 0.001);
}

// ---- comptime とジェネリクス ----
// Zig のジェネリクスは「型を受け取って型を返す関数」で表現する
fn Pair(comptime T: type) type {
    return struct {
        a: T,
        b: T,

        const Self = @This();

        fn swap(self: Self) Self {
            return .{ .a = self.b, .b = self.a };
        }
    };
}

test "ジェネリックな型" {
    const p: Pair(i32) = .{ .a = 1, .b = 2 };
    try expectEqual(2, p.swap().a);

    const s: Pair([]const u8) = .{ .a = "x", .b = "y" };
    try testing.expectEqualStrings("y", s.swap().a);
}

// anytype: 引数の型を呼び出し側から受け取る(コンパイル時に具体化される)
fn double(x: anytype) @TypeOf(x) {
    return x * 2;
}

test "anytype" {
    try expectEqual(4, double(@as(i32, 2)));
    try expectEqual(5.0, double(@as(f64, 2.5)));
}

// comptime: コンパイル時に実行される計算
fn fib(n: u32) u32 {
    return if (n < 2) n else fib(n - 1) + fib(n - 2);
}

test "comptime" {
    const v = comptime fib(10); // コンパイル時に計算済み
    try expectEqual(55, v);

    // 0.16 では @Type が廃止され、@Int / @Struct などの専用組み込み関数になった
    const U12 = @Int(.unsigned, 12);
    try expectEqual(12, @bitSizeOf(U12));
}
