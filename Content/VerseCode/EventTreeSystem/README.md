# EventTreeSystem

根から `SendDown` で流したイベントがツリーのどこまで届くかを、ノードの色で見せるサンプルです。`OnReceive` が `true` を返すと「消費」され、その先の子孫には届きません。

## 見どころ

- **scene_event の消費**：`tree_node_component` は `Pass` が true なら `false` を返して子へ通し（成功）、false なら `true` を返して止めます（失敗）。止めたノードより下は「未到達」のグレーのままになります。
- **ロジックと見た目の分離**：`tree_node_component` は見た目を持たず、結果を `tree_node_state_event` で同じ entity のコンポーネントへ知らせるだけ。色・パーティクル・大きさは別のコンポーネントを付け替えて決めます。
- **同じ entity だけに送る**：`Notify` は `Entity.GetComponents()` の各コンポーネントに `SendDown` するので、親や子の entity には届きません。
- **Verse の書き方**：状態は `enum`（`tree_node_state`）で持ち、`case` で分けています。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `tree_send_down_component` | `Interval` 秒ごとに `tree_reset_event` → 0.5 秒後に `tree_event` を `SendDown` | ツリーの根の entity | `Interval` |
| `tree_node_component` | `tree_event` を通すか止めるかを決め、`tree_node_state_event` を同じ entity へ知らせる | 根の子孫の各ノード | `Pass` |
| `tree_mesh_color_component` | 状態ごとにキューブの色を変える | `SM_TutorialCube` / `tree_node_component` と同じ entity | `SucceededColor`, `FailedColor`, `UnreachedColor` |
| `tree_particle_component` | 状態ごとにパーティクルを出す（未設定なら出さない） | `tree_node_component` と同じ entity | `SucceededParticle`, `FailedParticle`, `UnreachedParticle`, `Height` |
| `tree_scale_component` | 状態ごとに大きさを変える（子のノードも一緒に変わる） | `tree_node_component` と同じ entity | `SucceededScale`, `FailedScale`, `UnreachedScale` |

イベント：`tree_event`（流すイベント。`Root`：送り元の根）、`tree_reset_event`（全ノードを未到達に戻す。誰も止めない。`Root`）、`tree_node_state_event`（`Node`：送り元のノード、`State`）

## イベントの流れ

```
EventTreeRoot（tree_send_down_component）
  → SendDown(tree_reset_event) → 全ノード：Unreached（グレー）
  → SendDown(tree_event)
      → Node（Pass = true）：Succeeded、false を返す → 子へ続く
      → Node（Pass = false）：Failed、true を返す → 子孫には届かない（Unreached のまま）
  各ノード内：tree_node_component → tree_node_state_event → color / particle / scale
```

## レベルでの置き場所

エリア中心 (4000, 4000)。

- `EventTreeRoot`：根。子孫に `Node*` という名前のノードが並ぶ
- `VariantTreeScale`：色の代わりに `tree_scale_component` で大きさを変えるツリー

## 試してみよう

1. 途中の `Node*` の `Pass` を false にする。そのノードが赤になり、その下がグレーのまま残ります。
2. `tree_mesh_color_component` を外して `tree_scale_component` を付ける。同じ結果が「大きさ」で見えるようになります（親ノードが大きくなると子も一緒に大きくなります）。
3. `tree_particle_component` を足して `SucceededParticle` に好きなパーティクルを設定する。色と並べて使えます。
4. `EventTreeRoot` の `Interval` を変えて、流れる周期を変える。

## UE5 との違い

- UE5 のイベントディスパッチャーは登録したリスナー全員に届き、途中で止める仕組みはありません。scene_event は親子関係に沿って流れ、`OnReceive` で `true` を返すとそこで止められます（入力の「消費」に近い考え方）。
