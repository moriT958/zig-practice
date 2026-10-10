# Zig 0.16 学習ノート

Zig 0.16.0 で動作確認済みのサンプル集です。各ファイルが単体で動き、
コメントに解説を書いています。上から順に読み、値を書き換えて試してください。

### 0.16 編

| 章 | ファイル | 内容 | 実行方法 |
|---|---|---|---|
| 1 | `01_hello.zig` | Hello World、`std.process.Init`、標準出力 | `zig run learn/01_hello.zig` |
| 2 | `02_basics.zig` | 変数、型、if / while / for / switch | `zig test learn/02_basics.zig` |
| 3 | `03_errors.zig` | エラー処理、optional、defer / errdefer | `zig test learn/03_errors.zig` |
| 4 | `04_memory.zig` | アロケータ、ArrayList、HashMap | `zig test learn/04_memory.zig` |
| 5 | `05_types.zig` | struct、enum、union、comptime | `zig test learn/05_types.zig` |
| 6 | `06_file_io.zig` | ファイル I/O、引数、環境変数 | `zig run learn/06_file_io.zig -- a b` |
| 7 | `07_concurrency.zig` | `io.async`、`Io.Group` | `zig run learn/07_concurrency.zig` |

### 基本文法編

| 章 | ファイル | 内容 | 実行方法 |
|---|---|---|---|
| 8 | `08_pointers.zig` | ポインタ、スライス、`?*T` | `zig test learn/08_pointers.zig` |
| 9 | `09_strings.zig` | 文字列、`std.mem`、数値変換、UTF-8 | `zig test learn/09_strings.zig` |
| 10 | `10_modules.zig` | `@import`、`pub`、ファイル分割 | `zig test learn/10_modules.zig` |
| 11 | `11_testing.zig` | `test`、`std.testing` | `zig test learn/11_testing.zig` |
| 12 | `12_control_flow.zig` | キャプチャ、switch の発展、ラベル | `zig test learn/12_control_flow.zig` |

HTML 版は `zig-0.16-guide.html` をブラウザで開いてください。

## 0.16 で特に変わった点

- I/O は `std.Io` の値(`io`)を明示的に渡す。`main(init: std.process.Init)` から `init.io` を受け取る
- `std.io.getStdOut()`、`std.fs.cwd()` は廃止。`Io.File.stdout()`、`Io.Dir.cwd()` を使う
- `ArrayList` はアロケータを保持せず、`append(gpa, x)` のように都度渡す
- `@Type` は廃止され、`@Int` などの専用組み込み関数になった
- 環境変数・引数も `init` 経由で受け取る

## 詰まったときの調べ方

標準ライブラリのソースが一番正確です。

```bash
ls "$(zig env | grep std_dir | cut -d'"' -f2)"
grep -rn "pub fn writeFile" "$(zig env | grep std_dir | cut -d'"' -f2)/Io"
```

- [公式リリースノート 0.16.0](https://ziglang.org/download/0.16.0/release-notes.html)
- [公式 日本語 Learn](https://ziglang.org/ja-JP/learn)
- [Ziglings](https://codeberg.org/ziglings/exercises)(演習形式)

## 次にやること

- 各章の末尾に自分でテストを足す
- `build.zig` を読み、`zig build run` / `zig build test` の仕組みを理解する(`src/` が題材)
- 小さな CLI(例: `wc` や `grep` の簡易版)を作る
