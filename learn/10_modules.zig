//! 第 10 章(基本文法編): ファイル分割・pub・モジュール
//!
//! 実行: zig test learn/10_modules.zig
//!
//! - `@import("file.zig")` はそのファイルを 1 つの構造体として取り込む
//! - `pub` を付けた宣言だけが外から見える
//! - `@import("std")` のように名前だけのものは標準ライブラリや、
//!   build.zig で登録したモジュール(例: このリポジトリの "zig_practice")

const std = @import("std");
const helper = @import("10_modules_helper.zig");
const expectEqual = std.testing.expectEqual;

test "import したファイルを使う" {
    try std.testing.expectEqualStrings("1.0", helper.version);

    var buf: [64]u8 = undefined;
    const msg = try helper.greet("Zig", &buf);
    try std.testing.expectEqualStrings("こんにちは、Zigさん", msg);

    // helper.secret() は pub でないのでコンパイルエラーになる
    try expectEqual(42, helper.reveal());
}

test "import した型" {
    var c: helper.Counter = .{};
    c.inc();
    c.inc();
    try expectEqual(2, c.count);
}

// ファイルの中の宣言は、順序に関係なく参照できる(トップレベルのみ)
const answer = double(21);
fn double(x: u32) u32 {
    return x * 2;
}

test "トップレベル宣言は順不同" {
    try expectEqual(42, answer);
}

// 名前空間としての struct。フィールドを持たない struct は単なるまとまりとして使える
const math = struct {
    pub const tau = 6.28;
    pub fn square(x: i32) i32 {
        return x * x;
    }
};

test "struct を名前空間として使う" {
    try expectEqual(9, math.square(3));
}

// インポートしたファイル内の test は、そのままでは走らない。
// 全部走らせたいときは次のように書く。
test {
    std.testing.refAllDecls(helper);
}
