# Scene Graph とは

Scene Graph は、UEFN で島の中身を「物（entity）」と「部品（component）」で組み立てる仕組みです。この会場の展示は、すべて Scene Graph で作られています。

## ひとことで言うと

「物は入れ物、動きは部品。部品を足したり外したりして、物の振る舞いを決める」考え方です。

- **entity**：島に置く物。場所と向きと大きさ、そして親子関係だけを持ちます。それ自体は何もしません。
- **component**：entity に付ける部品。見た目（メッシュ、ライト）、触れる仕組み（インタラクト）、アイテム、そして Verse で書いた自作の部品があります。

```
entity「ZoneGhost」
 ├ SM_TutorialVolumeCube        … 見た目（半透明の箱）
 ├ volume_detector_component    … 人が入った / 出たを調べる
 └ ghost_zone_component         … 入った人を透明にする
```
この 3 つを並べただけで「入ると透明になるゾーン」ができます。

## 会場の中心テーマ 1：部品の付け替えで動きが変わる

上の `ghost_zone_component` を外して `stasis_zone_component` を付けると、同じ箱が「入ると固まるゾーン」になります。Verse のコードは 1 行も変えません。

会場では、このパターンを展示ごとに用意しています。

| エリア | 共通の部品 | 付け替える部品 |
|---|---|---|
| プレイヤーゾーン | `volume_detector_component` | 固める / 透明 / テレポート / 操作方法の案内 |
| アビリティパッド | `ability_pad_component` | 回復 / ダメージ / 打ち上げ |
| レーザー | `laser_eye_component` | 誰を狙うか（プレイヤー / 往復 / マーカー）と、当たったときの反応 |
| パス | `path_runner_component` | 見た目（キューブ / 円柱）と、動き方（直線 / ジャンプ） |
| AI（ペルソナ） | `persona_npc_component` の派生 | 会話する / 言葉で指示を受ける / 話すだけ |

ポイントは、「人が入った」を調べる部品は会場に **1 種類しかない**ことです（`ZoneSystem/VolumeDetector.verse`）。入ったあとに何をするかだけを、別の部品が受け持ちます。

## 会場の中心テーマ 2：部品どうしは「知らせ」でつながる

部品は、ほかの部品を直接呼びません。代わりに **scene_event**（知らせ）を送ります。

- `SendUp`：自分の entity から、親・祖先へ知らせる（「入ったよ」「終わったよ」など、状態の報告）
- `SendDown`：自分の entity から、子・子孫へ知らせる（「始めて」「止まって」など、指示）
- 受け取る側は `OnReceive` で知らせを読み、自分に関係あるものだけに反応します

```
床の entity（AreaRoot の子）
  volume_detector_component ── SendUp「入った」 ──▶
  area_label_component      ── 受けて、SendUp「このエリアに入った」 ──▶
AreaRoot
  area_name_hud_component   ── 受けて、画面の右中央にエリア名を出す
```
床は HUD を知らず、HUD は床を知りません。床を 1 枚増やしても、HUD 側のコードは変わりません。
会場では **イベントツリーエリア**（`EventTreeSystem`）で、親から子へ知らせが流れていく様子を、色とパーティクルで見られます。

## 親子関係を「設定」として使う

entity は入れ子にできます。この会場では、親子関係そのものを設定の代わりに使っています。

- **ミニゲーム**（`GameLoopSystem`）：ゲームの流れを「子 entity を順番に実行する」形にしてあります。子を入れ替えれば別のゲームになります。
- **同時進行の門**（`SyntaxSystem` の SyncGate）：親が 2 つの子の床スイッチから「入った」を受け、両方そろったら開きます。
- **エリアの床**：`AreaRoot` の下に床を並べるだけで、右中央のエリア名が動きます。

## 部品の一生

Verse で書いた部品には、決まったタイミングで呼ばれる場所があります。

| いつ | 何を書くか |
|---|---|
| `OnBeginSimulation` | 開始時の設定（色を塗る、知らせの購読） |
| `OnSimulate` | 待ちや繰り返し（光らせ続ける、入るのを待つ） |
| `OnReceive` | 知らせを受け取ったときの処理 |
| `OnEndSimulation` | 片付け |

## Unreal Engine 5 との違い

| | UE5 | Scene Graph（UEFN） |
|---|---|---|
| 物 | Actor（それ自体にロジックを書ける） | entity（場所と親子だけ。ロジックは持たない） |
| 部品 | ActorComponent | component（公式の部品と Verse の自作部品が同列） |
| 種類の違い | Blueprint クラスを派生させる | 付ける部品を変える |
| 部品間の連絡 | 参照を持って直接呼ぶ、イベントディスパッチャー | scene_event を親子方向に送る。参照は持たない |
| 再利用 | Blueprint クラス | プレハブ（entity の組み合わせを保存） |
| 入った / 出たの検知 | Overlap イベント | 会場では共通の検知部品が調べ、知らせを送る |

## もっと知りたいとき

- [what-is-verse.md](what-is-verse.md)：部品の中身を書いている言語
- [difference-between-other-engines.md](difference-between-other-engines.md)：Unity・UE5・Godot と比べると何に当たるか
- `ZoneSystem/README.md`：共通の検知部品と、付け替えで変わるゾーン
- `EventTreeSystem/README.md`：知らせが親から子へ流れる様子
- `LayoutSystem/README.md`：床 → 親 → 画面、という SendUp の実例
- 各 System フォルダの `README.md`：「試してみよう」にエディターで部品を付け替える手順があります
