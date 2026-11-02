# UtilitySystem

ほかの System が共通で使う小さな関数を集めた土台です。コンポーネントは持たず、「重なった entity からプレイヤーを取り出す」「キューブを塗る」「文字列を message にする」といった、どの展示でも同じになる処理だけを置いています。

## 見どころ

- **依存は一方向**：各 System → UtilitySystem の向きだけです。UtilitySystem はほかの System を知りません。
- **拡張関数**：`(Other:entity).FindPlayer[]` のように、型の後ろに関数を足す書き方をしています。呼ぶ側は `Other.FindPlayer[]` と書けます。
- **失敗できる関数**：`FindCharacter[]` / `FindPlayer[]` は `<decides>` なので、見つからなければ失敗します。`if (Player := Other.FindPlayer[])` のように条件の中で使います。

## 関数一覧

| 関数 | 役割 | 使う場面 |
|---|---|---|
| `(entity).FindCharacter[]` | entity のコンポーネントから `fort_character` を取り出す | 重なった相手がキャラクターか調べる |
| `(entity).FindPlayer[]` | entity から `player` を取り出す（NPC やプロップなら失敗） | ゾーン、パッド、入口 |
| `(mesh_component).SetupAsTrigger()` | 当たり判定なし・重なり検知ありにする | ゾーンやパッドのメッシュ |
| `(entity).PaintCube(color)` | `SM_TutorialCube` か `SM_TutorialVolumeCube` を指定の色で塗る | 状態を色で見せる展示すべて |
| `MakeCubeMesh(entity, color)` | 実行時に組み立てる entity 用の色付きキューブを作る | 実行時生成（BuildSystem、PathSystem など） |
| `(entity).SetUniformScale(float)` | 大きさだけを変える（位置と向きはそのまま） | 実行時生成した本体の大きさ、イベントツリーのノード |
| `LerpColor(color, color, float)` | 2 色のあいだを 0〜1 の比率で混ぜる | 体力の割合、ライトの明滅 |
| `([player]t).WithoutPlayer(player)` | map から 1 人ぶんを除いた map を作る（map の要素は消せないので作り直す） | ゾーンの出入り、カメラの追従 |
| `TextMessage(string)` | `@editable` の文字列を UI や AI に渡せる `message` にする | 看板、クエスト、AI の指示 |

## イベントの流れ

```
（イベントは扱わない。各 System の関数から直接呼ばれる）
```

## レベルでの置き場所

置くものはありません。

## 試してみよう

1. どれかの展示の `PaintCube` の呼び出しを探し、色を変えてみる。塗る処理は 1 か所なので、どの展示でも同じ書き方になっています。
2. `FindPlayer[]` を使っている System を数えてみる（ゾーン、パッド、入口、クエスト、売買など）。

## UE5 との違い

- UE5 では共通処理を Blueprint 関数ライブラリや C++ の静的関数に置きます。Verse では module の直下に関数を書くだけで、`using { UtilitySystem }` した側から呼べます。
- 拡張関数（`(entity).FindPlayer`）は、既存の型に手を入れずにメソッドのような呼び方を足せる書き方です。
