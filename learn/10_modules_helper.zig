//! 第 10 章で import される補助ファイル。
//! Zig ではファイル 1 つがそのまま 1 つの構造体(名前空間)です。

const std = @import("std");

/// `pub` が付いたものだけが外部から見える
pub const version = "1.0";

pub fn greet(name: []const u8, buf: []u8) ![]const u8 {
    return std.fmt.bufPrint(buf, "こんにちは、{s}さん", .{name});
}

/// pub が付いていない関数は、このファイル内でしか使えない
fn secret() u32 {
    return 42;
}

pub fn reveal() u32 {
    return secret();
}

pub const Counter = struct {
    count: u32 = 0,

    pub fn inc(self: *Counter) void {
        self.count += 1;
    }
};

test "このファイルのテストは import 元から実行されない(必要なら refAllDecls を使う)" {
    try std.testing.expectEqual(42, secret());
}
