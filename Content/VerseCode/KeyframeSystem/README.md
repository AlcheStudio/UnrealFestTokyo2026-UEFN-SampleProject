# KeyframeSystem

公式の `keyframed_movement_component` に、Verse からキーフレーム（移動量・回転・時間）を設定して動かすサンプルです。

## 見どころ

- **公式コンポーネントとの組み合わせ**：動かすのは公式の `keyframed_movement_component`。このシステムのコンポーネントは「どう動くか」を設定するだけです。
- **再生モードの切り替え**：`PingPong` で `pingpong_keyframed_movement_playback_mode`（行って戻る）と `loop_keyframed_movement_playback_mode`（同じ動きを繰り返す）を選びます。回転だけなら `loop` が向いています。
- **ほかのシステムとの連携**：`PlayOnStart` を false にして、InteractSystem の `switch_keyframe_component` から `Play` / `Pause` させることができます（`SwitchLift` で使用）。
- **Verse の書き方**：`keyframed_movement_delta` に `transform`、`Duration`、`Easing`（`ease_in_out_cubic_bezier_easing_function`）を入れて 1 つのキーフレームを作ります。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `keyframe_loop_component` | `Offset` だけ動いて `Spin` 度回るキーフレームを設定し、必要なら再生する | `keyframed_movement_component` と同じ entity | `Offset`, `Spin`, `MoveTime`, `PingPong`, `PlayOnStart` |

## イベントの流れ

```
OnBeginSimulation
  → keyframed_movement_delta{Offset, Spin, MoveTime} を作る
  → SetKeyframes(…, pingpong か loop)
  → PlayOnStart なら Play()
```

## レベルでの置き場所

エリア中心 (-4000, 4000)（LightSystem と同じエリア）。

- `KeyframeSample`：上下に行って戻る例
- `VariantKeyframeSpin`：`Spin` を使って回り続ける例

## 試してみよう

1. `KeyframeSample` の `Offset` を `Forward := 300` などに変える。横へ行って戻るようになります。
2. `Spin` を 90 にして、移動しながら回るようにする。
3. `VariantKeyframeSpin` の `PingPong` を true にする。回っては戻る動きに変わります。
4. `MoveTime` を短く / 長くして速さを変える。

## UE5 との違い

- UE5 の Timeline や Sequencer で動きを作る代わりに、キーフレームを Verse で組み立てて公式コンポーネントに渡しています。
