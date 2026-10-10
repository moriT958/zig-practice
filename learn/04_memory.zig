//! 第 4 章: アロケータとコレクション
//!
//! 実行: zig test learn/04_memory.zig
//!
//! Zig にはグローバルなメモリ確保がありません。確保が必要な関数は
//! `std.mem.Allocator` を引数で受け取り、呼び出し側が解放の責任を持ちます。
//!
//! 0.16 のポイント
//!   - ArrayList は「アロケータを保持しない」形(`.empty` で初期化)が標準。
//!     append / deinit のたびにアロケータを渡す。
//!   - テストでは `std.testing.allocator` を使うとリークを自動検出してくれる。
//!   - アプリでは `init.gpa`(汎用)や `init.arena`(一括解放)が渡される。

const std = @import("std");
const testing = std.testing;
const expectEqual = testing.expectEqual;

test "alloc / free" {
    const gpa = testing.allocator;

    const buf = try gpa.alloc(u8, 4);
    defer gpa.free(buf); // コメントアウトするとリークとして検出される
    @memset(buf, 'z');
    try testing.expectEqualStrings("zzzz", buf);

    // 1 個だけ確保するなら create / destroy
    const p = try gpa.create(i32);
    defer gpa.destroy(p);
    p.* = 42;
    try expectEqual(42, p.*);
}

test "ArrayList" {
    const gpa = testing.allocator;

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa);

    try list.append(gpa, 1);
    try list.append(gpa, 2);
    try list.appendSlice(gpa, &.{ 3, 4 });

    try expectEqual(4, list.items.len);
    try expectEqual(3, list.items[2]);
    try expectEqual(4, list.pop()); // 0.16 では ?T を返す
}

test "HashMap" {
    const gpa = testing.allocator;

    var map: std.StringHashMapUnmanaged(u32) = .empty;
    defer map.deinit(gpa);

    try map.put(gpa, "apple", 3);
    try map.put(gpa, "banana", 5);

    try expectEqual(3, map.get("apple").?);
    try expectEqual(null, map.get("cherry"));
    try expectEqual(2, map.count());
}

test "ArenaAllocator は一括解放" {
    // arena は個別の free が不要。deinit で全てまとめて解放する。
    // リクエスト単位・コマンド単位の処理など、寿命が揃うデータに向く。
    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const x = try a.alloc(u8, 100);
    const y = try a.dupe(u8, "hello");
    _ = x;
    try testing.expectEqualStrings("hello", y);
    // free を呼ばなくてもリークにならない
}

test "FixedBufferAllocator はスタック上で完結" {
    var storage: [16]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&storage);
    const a = fba.allocator();

    _ = try a.alloc(u8, 10);
    try testing.expectError(error.OutOfMemory, a.alloc(u8, 10));
}

test "std.fmt で文字列を作る" {
    const gpa = testing.allocator;
    const s = try std.fmt.allocPrint(gpa, "{s}-{d}", .{ "id", 7 });
    defer gpa.free(s);
    try testing.expectEqualStrings("id-7", s);

    // バッファを渡す版ならアロケータ不要
    var buf: [16]u8 = undefined;
    const t = try std.fmt.bufPrint(&buf, "{x}", .{255});
    try testing.expectEqualStrings("ff", t);
}
