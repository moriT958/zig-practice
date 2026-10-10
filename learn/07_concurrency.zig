//! 第 7 章: 非同期処理と並行処理(std.Io の本領)
//!
//! 実行: zig run learn/07_concurrency.zig
//!
//! 0.16 では「関数に色が付かない」async を `Io` が提供します。
//!   - `io.async(f, .{args})`     : f を非同期に呼ぶ。await で結果を受け取る。
//!                                  Io の実装次第で、その場で逐次実行されることもある。
//!   - `io.concurrent(f, .{args})`: 本当に並行実行することを要求する。
//!   - `Io.Group`                 : 複数のタスクをまとめて待つ。
//! どの実装(スレッドプール等)で動かすかは main を呼ぶ側が決めており、
//! 呼び出されるコードは `io` を受け取るだけで済みます。

const std = @import("std");
const Io = std.Io;

fn slowAdd(io: Io, a: i32, b: i32) i32 {
    io.sleep(.fromMilliseconds(100), .awake) catch {};
    return a + b;
}

fn worker(io: Io, name: []const u8, ms: i64) void {
    io.sleep(.fromMilliseconds(ms), .awake) catch return;
    std.debug.print("  {s} 完了 ({d}ms)\n", .{ name, ms });
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // ---- async / await ----
    std.debug.print("[async / await]\n", .{});
    const t0 = Io.Clock.awake.now(io);

    var f1 = io.async(slowAdd, .{ io, 1, 2 });
    var f2 = io.async(slowAdd, .{ io, 10, 20 });
    const r1 = f1.await(io);
    const r2 = f2.await(io);

    const elapsed = t0.untilNow(io, .awake);
    std.debug.print("  結果: {d}, {d} / 経過 {d}ms\n", .{
        r1, r2, elapsed.toMilliseconds(),
    });

    // ---- Group: 複数タスクをまとめて待つ ----
    std.debug.print("[Group]\n", .{});
    var group: Io.Group = .init;
    defer group.cancel(io); // 途中でエラー終了しても確実に後始末する
    group.async(io, worker, .{ io, "A", 300 });
    group.async(io, worker, .{ io, "B", 100 });
    group.async(io, worker, .{ io, "C", 200 });
    try group.await(io);
    std.debug.print("  全タスク完了\n", .{});
}
