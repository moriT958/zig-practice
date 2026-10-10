//! 第 3 章: エラー処理・Optional・defer
//!
//! 実行: zig test learn/03_errors.zig
//!
//! Zig には例外がありません。失敗は「値」として扱います。
//!   - `!T`  : エラーまたは T (error union)
//!   - `?T`  : null または T (optional)

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

const DivError = error{DivideByZero};

fn divide(a: i32, b: i32) DivError!i32 {
    if (b == 0) return error.DivideByZero;
    return @divTrunc(a, b);
}

test "try / catch" {
    try expectEqual(3, try divide(9, 3));
    try expectError(error.DivideByZero, divide(1, 0));

    // catch でデフォルト値に置き換える
    const r = divide(1, 0) catch -1;
    try expectEqual(-1, r);

    // エラーごとに処理を分ける
    const msg = if (divide(1, 0)) |_| "ok" else |err| switch (err) {
        error.DivideByZero => "0 で割れません",
    };
    try std.testing.expectEqualStrings("0 で割れません", msg);
}

fn calc(a: i32, b: i32) !i32 {
    // try は「エラーならそのまま呼び出し元へ返す」の略記
    const q = try divide(a, b);
    return q + 1;
}

test "エラーの伝播" {
    try expectEqual(4, try calc(9, 3));
    try expectError(error.DivideByZero, calc(9, 0));
}

fn findIndex(items: []const i32, target: i32) ?usize {
    for (items, 0..) |item, i| {
        if (item == target) return i;
    }
    return null;
}

test "optional" {
    const items = [_]i32{ 5, 6, 7 };

    // if でアンラップ
    if (findIndex(&items, 6)) |idx| {
        try expectEqual(1, idx);
    } else {
        return error.TestUnexpectedResult;
    }

    // orelse でデフォルト値
    try expectEqual(0, findIndex(&items, 99) orelse 0);

    // .? は null なら panic(確実に非 null と分かっているときだけ)
    try expectEqual(2, findIndex(&items, 7).?);
}

test "defer と errdefer" {
    var log: [3]u8 = undefined;
    var n: usize = 0;

    {
        // defer はスコープを抜けるときに(逆順で)実行される
        defer {
            log[n] = 'C';
            n += 1;
        }
        defer {
            log[n] = 'B';
            n += 1;
        }
        log[n] = 'A';
        n += 1;
    }
    try std.testing.expectEqualStrings("ABC", &log);
}

var cleaned_up = false;

fn mayFail(fail: bool) !void {
    // errdefer はエラーで関数を抜けるときだけ実行される。
    // 確保したリソースを失敗時に解放する用途で使う。
    errdefer cleaned_up = true;
    if (fail) return error.Oops;
}

test "errdefer" {
    cleaned_up = false;
    try mayFail(false);
    try expect(!cleaned_up);

    try expectError(error.Oops, mayFail(true));
    try expect(cleaned_up);
}
