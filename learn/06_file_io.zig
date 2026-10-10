//! 第 6 章: ファイル I/O とコマンドライン引数
//!
//! 実行: zig run learn/06_file_io.zig -- foo bar
//!
//! 0.16 の最大の変更点。ファイル、時計、プロセスなど外界に触れる操作は
//! すべて `Io` 値を受け取ります。旧 `std.fs.cwd()` は `std.Io.Dir.cwd()` に、
//! ファイル操作のメソッドは第 1 引数に `io` を取る形に変わりました。

const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buf);
    const out = &stdout_writer.interface;

    // ---- コマンドライン引数 ----
    // arena は main の終わりまで生きる。ここで確保したものは解放不要
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    for (args, 0..) |arg, i| {
        try out.print("args[{d}] = {s}\n", .{ i, arg });
    }

    // ---- 環境変数 ----
    // 0.16 では環境変数もグローバル関数ではなく init 経由
    if (init.environ_map.get("HOME")) |home| {
        try out.print("HOME = {s}\n", .{home});
    }

    // ---- 書き込み ----
    const cwd = Io.Dir.cwd();
    const path = ".zig-cache/learn_06_sample.txt";

    try cwd.writeFile(io, .{
        .sub_path = path,
        .data = "1 行目\n2 行目\n3 行目\n",
    });

    // ---- まとめて読み込み ----
    // 第 5 引数は読み込む上限サイズ。超えると error.StreamTooLong
    const content = try cwd.readFileAlloc(io, path, gpa, .limited(1024));
    defer gpa.free(content);
    try out.print("読み込んだ: {d} バイト\n", .{content.len});

    // ---- 行ごとに処理 ----
    var lines = std.mem.splitScalar(u8, content, '\n');
    var n: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        n += 1;
        try out.print("  {d}: {s}\n", .{ n, line });
    }

    // ---- 存在しないファイルのエラー処理 ----
    if (cwd.openFile(io, "no_such_file.txt", .{})) |file| {
        file.close(io);
    } else |err| switch (err) {
        error.FileNotFound => try out.print("no_such_file.txt は無い\n", .{}),
        else => return err,
    }

    try cwd.deleteFile(io, path);
    try out.flush();
}
