# ほかのゲームエンジンとの違い

UEFN（Unreal Editor for Fortnite）は「フォートナイトの中に島を作るためのエディター」です。ふつうのゲームエンジンとは、作るものも、動かし方も、ロジックの書き方も少しずつ違います。この会場で見る Verse と Scene Graph が、ほかのエンジンのどれに当たるかを整理します。

## ひとことで言うと

- **Unity / Unreal Engine 5 / Godot**：ゲームそのものを作り、自分で配布する。
- **UEFN**：フォートナイトの中で遊べる「島」を作る。配布・サーバー・プレイヤー・ボイスチャット・アイテムの仕組みは、フォートナイト側が持っている。

そのぶん、UEFN では「島の中で何が起きるか」だけを書きます。この会場の Verse は、すべてその部分です。

## 物の表し方

| | Unity | Unreal Engine 5 | Godot | UEFN（Scene Graph） |
|---|---|---|---|---|
| 置く物 | GameObject | Actor | Node | entity |
| 機能の部品 | Component（MonoBehaviour） | ActorComponent | 子 Node | component |
| 物自体にロジックを書けるか | 書けない（部品に書く） | 書ける（Actor を派生） | 書ける（Node を派生） | 書けない（部品に書く） |
| 親子関係 | Transform の親子 | Attach | シーンツリー | entity の親子 |
| まとめて再利用 | Prefab | Blueprint クラス | シーン（.tscn） | プレハブ |

UEFN の考え方は Unity にいちばん近く、「物は入れ物、動きは部品」です。違いは、**公式の部品（メッシュ、ライト、インタラクト、アイテム、AI の NPC）と自分で書いた部品が、同じ列に並ぶ**ことです。会場では `ZoneGhost` のように、公式の箱 ＋ 共通の検知部品 ＋ 自作の効果部品を 1 つの entity に並べています（[what-is-scene-graph.md](what-is-scene-graph.md)）。

## 部品どうしの連絡

| | Unity | Unreal Engine 5 | Godot | UEFN |
|---|---|---|---|---|
| よくある方法 | 参照を持って直接呼ぶ、UnityEvent | 参照を持って直接呼ぶ、イベントディスパッチャー | Signal（接続して呼ぶ） | scene_event を親子の方向に送る |
| 相手を知っているか | 知っている（参照を持つ） | 知っている | つなぐときに知る | **知らない**（親か子へ送るだけ） |

UEFN では、部品は「上へ知らせる（SendUp）」「下へ指示する（SendDown）」の 2 方向だけで話します。兄弟には届きません。相手の参照を持たないので、部品を足しても外しても、ほかの部品のコードは変わりません。会場の床 → 親 → 画面右中央のエリア名は、この形の実例です。

## ロジックの書き方

| | Unity | Unreal Engine 5 | Godot | UEFN |
|---|---|---|---|---|
| 言語 | C# | C++ / Blueprint | GDScript / C# | Verse |
| 毎フレームの処理 | `Update()` | `Tick()` | `_process()` | 待つ処理を `loop` に書く（`Sleep` / `Await`） |
| 時間のかかる処理 | コルーチン、async | Timer、Latent ノード | `await` | 関数に `<suspends>` を付け、`race` / `sync` で競わせる・そろえる |
| 失敗の扱い | null チェック、例外 | `IsValid`、戻り値 | null チェック | `[ ]` で呼ぶと失敗が制御構造になる |
| 置ける値 | `[SerializeField]` | `UPROPERTY(EditAnywhere)` | `@export` | `@editable` |

Verse の特徴は「待つ」と「失敗する」が言語に組み込まれていることです（[what-is-verse.md](what-is-verse.md)）。会場の **Verse の文法エリア** では、制限時間との競走や、2 つの床スイッチがそろうまで待つ処理を、タイマーやフラグなしで書いています。

## 動かし方・配布

| | Unity / UE5 / Godot | UEFN |
|---|---|---|
| 試す | エディターで Play | 島をセッションとして起動し、フォートナイトのクライアントで遊ぶ |
| 配布 | 自分でビルドして配る | フォートナイトに公開する（審査あり） |
| サーバー・マルチプレイ | 自分で用意する | フォートナイト側が持っている |
| 課金 | 自分で組む | V-Bucks の商品として定義する（会場の **有料アイテム** エリア） |
| 実験的な機能 | 任意 | 使うと公開できない（AI の会話、クエスト、タイマーなど。会場の一部） |

## 「違うように見えて、同じこと」

- Unity の Prefab と UEFN のプレハブは、どちらも「物の組み合わせを保存して使い回す」仕組みです。会場の展示 55 個はプレハブになっています。
- Godot の Signal と Verse の `event` / `listenable` は、どちらも「起きたことを待つ・購読する」仕組みです。
- UE5 の Overlap イベントと会場の共通の検知部品は、どちらも「入った / 出た」を取りますが、会場では 1 つの部品が調べて知らせを送り、受け手は知らせを読むだけにしています。

## もっと知りたいとき

- [what-is-verse.md](what-is-verse.md)：言語の基本
- [what-is-scene-graph.md](what-is-scene-graph.md)：entity と component、知らせの流れ
- [how-to-use-mcp.md](how-to-use-mcp.md)：AI でエディターを操作する
- 各 System フォルダの `README.md`：末尾に「UE5 との違い」があります
