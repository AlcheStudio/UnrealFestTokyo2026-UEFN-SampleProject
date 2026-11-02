# CylinderSystem

ホログラムのシリンダーにプレイヤーが出入りしたことを `SendUp` で知らせ、受け取る側のコンポーネントを付け替えて反応を変える、最初のチュートリアルです。

## 見どころ

- **モジュール化**：`volume_cylinder_component` は見た目（ホログラム）だけ、出入りを知らせるのは ZoneSystem の `volume_detector_component` だけ。何をするか（Print する / 色を変える）は `section_cylinder_*` のどれを付けるかで決まります。
- **出入りの検知は detector に任せる**：シリンダーの entity に `volume_detector_component` を並べて付けると、出入りが `volume_entered_event` / `volume_exited_event` として `SendUp` されます。継承はしません。シリンダーの形（`SM_TutorialCylinder`）なら、detector は円柱として位置を調べます。
- **scene_event の SendUp**：イベントは自分の entity から親へ向かって上がります。同じ entity にも親 entity にも届くので、受け取り側はどちらに付けても動きます。
- **消費しない**：受け取り側はどれも `false` を返すので、イベントは親へ届き続けます。`true` を返すとそこで止まります。
- **どのボリュームの知らせか**：イベントの `Volume` が送り元のボリュームの entity です。`section_cylinder_color_component` は `Volume = Entity`（自分のシリンダー）のときだけ反応し、`section_cylinder_print_component` は見分けずに受けて「この entity / 子孫の entity」を添えて Print します（親に置いて子をまとめて見るため）。
- **Verse の書き方**：`volume_entered_event[SceneEvent]` のように、型を `[]` で指定して「その型なら成功」のキャストをしています。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `volume_cylinder_component` | 見た目（色・不透明度・上へ消える高さ・明るさ・パルス）を設定する。出入りは調べない | `SM_TutorialCylinder` と同じ entity | `Color`, `Opacity`, `FadeHeight`, `Glow`, `PulsePeriod` |
| `volume_detector_component`（ZoneSystem） | 出入りを調べて `volume_entered_event` / `volume_exited_event` を `SendUp` | `SM_TutorialCylinder` と同じ entity（シリンダーごとに 1 つ） | `PollInterval` |
| `section_cylinder_print_component` | 出入りを Print する（自分の entity か子孫の entity かも添える） | `volume_detector_component` と同じ entity か、その親 | `Label` |
| `section_cylinder_color_component` | 誰かが入っているあいだ色を `EnterColor` にし、全員出たら（detector の `InsideCount` が 0）元の色に戻す | `SM_TutorialCylinder` / `volume_cylinder_component` / `volume_detector_component` と同じ entity | `EnterColor` |

イベント：`volume_entered_event` / `volume_exited_event`（ZoneSystem。`Player`、`Character`、`Volume`：どのシリンダーか）

## イベントの流れ

```
プレイヤーがシリンダーに入る
  → volume_detector_component：プレイヤーか確かめ、SendUp(volume_entered_event{Volume := シリンダーの entity})
      → 同じ entity の section_cylinder_*（false を返す）
      → 親 entity の section_cylinder_print_component（false を返す）
      → さらに上の親へ…
```

## レベルでの置き場所

エリア中心 (4000, 0)。

- `TutorialCylinder`：シリンダー 1 本の基本形
- `VariantCylinderParent`：親 entity。子に `CylinderChildA` / `CylinderChildB` のシリンダーを持ち、親で両方の出入りを受け取る例

シリンダーの entity（`TutorialCylinder`、`CylinderChildA`、`CylinderChildB`）には、それぞれ `volume_detector_component` を付けます。親の `VariantCylinderParent` には付けません（子の知らせが SendUp で届くため）。

## 試してみよう

1. `TutorialCylinder` の `section_cylinder_print_component` を外して `section_cylinder_color_component` を付ける。入ると Print の代わりに色が変わります。
2. `volume_cylinder_component` の `Color` / `PulsePeriod` / `FadeHeight` を変えて見た目を調整する。
3. `VariantCylinderParent` に付いた `section_cylinder_print_component` の `Label` を変えて、`CylinderChildA` と `CylinderChildB` のどちらに入っても親の Print が出ることを確かめる。
4. 子の `section_cylinder_print_component` の `OnReceive` が `true` を返したらどうなるか考えてみる（親には届かなくなります）。

## UE5 との違い

- UE5 では Actor のオーバーラップイベントを Blueprint でバインドしたり、イベントディスパッチャーで相手を指定して呼びます。Scene Graph では送り手は相手を知らず、`SendUp` で親子関係に沿って流すだけです。
