# Verse とは

Verse は、Epic Games が UEFN（Unreal Editor for Fortnite）のために作ったプログラミング言語です。この会場の展示は、すべて Verse で書かれています。

## ひとことで言うと

「フォートナイトの島に、自分のルールを足すための言語」です。
エディターで物を置くだけでは作れない動き（入ったら光る、3 つ倒したらゴールが開く、AI の NPC と話す）を、短い文章のようなコードで書きます。

## どんな見た目か

```verse
# 役割：キューブに入ったら色を変える
OnReceive<override>(SceneEvent:scene_event):logic =
    if (Entered := volume_entered_event[SceneEvent]):
        Entity.PaintCube(SyntaxSuccessColor)
    false
```

- `#` から行末まではコメント（説明文）。この会場のコードは、各部品の先頭に「役割 / 置き方 / 同じ entity / 親 / 子」を日本語で書いてあります。
- 字下げ（インデント）でまとまりを表します。波かっこは要りません。
- `Entity.PaintCube(...)` のように、「誰の・何を」の順で読めます。

## Verse らしい 3 つの考え方

### 1. 「失敗するかもしれない」を文法で扱う
`volume_entered_event[SceneEvent]` の `[ ]` は「できないこともある」印です。できたときだけ `if` の中が動き、できなければ何も起きません。
エラーで止まるのではなく「試してだめなら次へ」が自然に書けるので、ゲームの判定（入っているか、持っているか、まだ生きているか）がそのまま読めるコードになります。

### 2. 待つ・競わせる・同時に進めるが、そのまま書ける
```verse
Reached := race:
    block:
        Detector.PlayerEnteredEvent.Await()   # 誰かが入るのを待つ
        true
    block:
        Sleep(TimeLimit)                      # 制限時間を待つ
        false
```
「入る」と「時間切れ」を競走させ、先に終わった方の結果を使います。ほかの言語ならタイマーとフラグを自分で管理するところを、Verse は `race` / `sync` / `Sleep` / `Await` という言葉で書けます。
会場では **Verse の文法エリア**（`SyntaxSystem`）で、この競走（RaceTimer）と、2 つの床スイッチがそろうまで待つ同時進行（SyncGate）を見られます。

### 3. 「何が起きうるか」を関数に書く
関数には `<suspends>`（時間がかかる）、`<decides>`（失敗しうる）といった印を付けます。印を見れば「この処理は待つのか」「失敗するのか」が分かり、コンパイラーが間違った使い方を止めてくれます。

## 書いたコードはどう動くのか

Verse のコードは、島の中の **entity**（物）に付ける **component**（部品）として動きます。この会場の展示は、ほぼすべて「公式の部品 ＋ Verse で書いた部品」を 1 つの entity に並べたものです。
部品の付け替えだけで動きが変わる、という会場の中心テーマは、Verse そのものより Scene Graph の話なので、[what-is-scene-graph.md](what-is-scene-graph.md) に続きます。

## エディターから触れる値

```verse
# 入るまでの制限時間（秒）
@editable_number(float):
    MinValue := option{0.0}
    MaxValue := option{60.0}
    ToolTip := RaceTimerTimeLimitTip
TimeLimit<public>:float = 5.0
```
`@editable` を付けた値は、UEFN のエディターの詳細パネルに出ます。コードを書かない人が、制限時間や色や文字を変えられます。この会場の展示は、すべてこの形で調整できるようにしてあります。

## Unreal Engine 5（C++ / Blueprint）との違い

| | UE5 | Verse（UEFN） |
|---|---|---|
| 書く場所 | C++ か Blueprint（ノードをつなぐ） | テキストのコードだけ |
| 置く先 | Actor と ActorComponent | entity と component |
| 時間のかかる処理 | Timer、Latent ノード、Tick | `Sleep` / `Await` / `race` / `sync` を関数の中に書く |
| 失敗の扱い | 戻り値や `IsValid` を自分で調べる | `[ ]` で呼び、失敗したら自動で取り消される |
| 試す方法 | エディターで Play | 島をセッションとして起動（フォートナイトのクライアントで遊ぶ） |

## もっと知りたいとき

- [difference-between-other-engines.md](difference-between-other-engines.md)：ほかのエンジンの言語や書き方との対応
- 会場の **Verse の文法エリア**（`SyntaxSystem/README.md`）：競走・同時進行・取り消しの実例
- `UtilitySystem/`：どの展示からも呼ばれる小さな共通関数（10 行程度のものばかり）
- 各 System フォルダの `README.md`：その展示で使っている部品と、エディターで試せること
