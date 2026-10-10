//! 第 1 章: Hello, World と標準出力
//!
//! 実行: zig run learn/01_hello.zig
//!
//! 0.16 のポイント
//!   - main は `std.process.Init` を受け取れる(通称 Juicy Main)
//!   - I/O は暗黙のグローバルではなく、`Io` 値を明示的に渡して行う
//!   - `init.io` が実行環境から渡される `Io`、`init.gpa` / `init.arena` がアロケータ
//!   - 0.15 以前の `std.io.getStdOut()` は存在しない

const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // 1. 一番簡単な方法: バッファなしで書き込む
    try Io.File.stdout().writeStreamingAll(io, "hello world!\n");

    // 2. 書式付き出力: バッファ付きの Writer を作る
    var buffer: [1024]u8 = undefined;
    var stdout_writer: Io.File.Writer = .init(.stdout(), io, &buffer);
    const out = &stdout_writer.interface;

    try out.print("{s} から {d} 回挨拶します\n", .{ "Zig 0.16", 3 });
    for (0..3) |i| {
        try out.print("  挨拶 {d}\n", .{i + 1});
    }

    // バッファに溜まった分は flush しないと出力されない(忘れがち)
    try out.flush();

    // 3. デバッグ用: stderr に書く。Io 不要で手軽
    std.debug.print("これは stderr です\n", .{});
}
