//! 第 9 章(基本文法編): 文字列
//!
//! 実行: zig test learn/09_strings.zig
//!
//! Zig に文字列型はなく、文字列は UTF-8 のバイト列 `[]const u8` です。
//! リテラル "abc" の型は `*const [3:0]u8`(末尾に 0 が付く配列へのポインタ)で、
//! `[]const u8` に自動変換されます。

const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const expectEqual = testing.expectEqual;
const expectEqualStrings = testing.expectEqualStrings;

test "文字列はバイト列" {
    const s = "Zig";
    try expectEqual(3, s.len);
    try expectEqual('Z', s[0]); // 要素は u8
    try expectEqual(0, s[s.len]); // 番兵(0 終端)があるので添字 len も読める

    // 日本語は 1 文字 3 バイト。len は文字数ではなくバイト数
    try expectEqual(9, "日本語".len);
}

test "比較は == ではなく mem.eql" {
    const a = "hello";
    const b: []const u8 = "hello";
    // `a == b` はスライス同士なのでコンパイルエラー。中身の比較は mem.eql
    try testing.expect(mem.eql(u8, a, b));
    try expectEqualStrings("hello", b); // テストでは expectEqualStrings が便利
}

test "検索・判定" {
    const s = "hello, world";
    try expectEqual(7, mem.indexOf(u8, s, "world").?);
    try expectEqual(4, mem.indexOfScalar(u8, s, 'o').?);
    try testing.expect(mem.startsWith(u8, s, "hello"));
    try testing.expect(mem.endsWith(u8, s, "world"));
    try testing.expect(mem.containsAtLeast(u8, s, 2, "o"));
}

test "分割・トリム" {
    var it = mem.splitScalar(u8, "a,b,c", ',');
    try expectEqualStrings("a", it.next().?);
    try expectEqualStrings("b", it.next().?);
    try expectEqualStrings("c", it.next().?);
    try expectEqual(null, it.next());

    // 連続する区切りを 1 つとして扱う場合は tokenize
    var tok = mem.tokenizeScalar(u8, "  a   b  ", ' ');
    try expectEqualStrings("a", tok.next().?);
    try expectEqualStrings("b", tok.next().?);

    try expectEqualStrings("x", mem.trim(u8, "  x\n", " \n"));
}

test "連結" {
    // コンパイル時なら ++ で連結できる
    const s = "foo" ++ "bar";
    try expectEqualStrings("foobar", s);

    // 実行時の連結はアロケータが必要
    const gpa = testing.allocator;
    const joined = try mem.concat(gpa, u8, &.{ "ab", "cd", "ef" });
    defer gpa.free(joined);
    try expectEqualStrings("abcdef", joined);

    const csv = try mem.join(gpa, ",", &.{ "x", "y", "z" });
    defer gpa.free(csv);
    try expectEqualStrings("x,y,z", csv);
}

test "文字の種類" {
    try testing.expect(std.ascii.isDigit('7'));
    try testing.expect(std.ascii.isAlphabetic('a'));
    try expectEqual('A', std.ascii.toUpper('a'));

    var buf: [5]u8 = undefined;
    const upper = std.ascii.upperString(&buf, "hello");
    try expectEqualStrings("HELLO", upper);
}

test "数値との変換" {
    try expectEqual(123, try std.fmt.parseInt(i32, "123", 10));
    try expectEqual(255, try std.fmt.parseInt(u8, "ff", 16));
    try testing.expectError(error.InvalidCharacter, std.fmt.parseInt(i32, "12a", 10));
    try expectEqual(1.5, try std.fmt.parseFloat(f64, "1.5"));
}

test "UTF-8 を文字(コードポイント)単位で扱う" {
    const view = try std.unicode.Utf8View.init("日本語");
    var it = view.iterator();
    var n: usize = 0;
    while (it.nextCodepoint()) |_| n += 1;
    try expectEqual(3, n);
}

test "複数行文字列リテラル" {
    const text =
        \\1 行目
        \\2 行目
    ;
    try expectEqualStrings("1 行目\n2 行目", text);
}

test "書式指定" {
    var buf: [64]u8 = undefined;
    const s = try std.fmt.bufPrint(&buf, "{s}|{d:>5}|{x}|{b}|{d:.2}", .{ "id", 42, 255, 5, 3.14159 });
    try expectEqualStrings("id|   42|ff|101|3.14", s);
}
