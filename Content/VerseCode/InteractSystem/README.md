# InteractSystem

インタラクトで ON / OFF が切り替わるスイッチと、それに反応する子 entity のサンプルです。スイッチは子孫に `SendDown` で知らせるだけで、何が起きるかは子に付けたコンポーネントで決まります。

## 見どころ

- **モジュール化**：`interact_switch_component` はライトもリフトも知りません。子 entity に `switch_light_component` を付ければ灯り、`switch_keyframe_component` を付ければ動く床になります。
- **scene_event の SendDown**：`switch_changed_event` を親から子孫へ流します。反応側は `false` を返すので、子孫の全員に届きます。
- **公式コンポーネントの購読**：同じ entity の `interactable_component` の `SucceededEvent` を `Subscribe` し、`OnEndSimulation` で `Cancel` します。
- **長押しの 3 イベント**：Interact Duration を設定した `basic_interactable_component` では、`StartedEvent` が「押し始め」の時点で届きます。完了は `SucceededEvent`、途中で離すと `CanceledEvent` です。`interact_hold_component` はこの 3 つを購読して色を塗り分け、押し始めから完了までの秒数を Print します。
- **Verse の書き方**
  - 開始時は `TickEvents.PrePhysics.Await()` で 1 フレーム待ってから最初の状態を流します（子孫の準備を待つため）。
  - `Changed.On <> Invert` で、`Invert` が true のときだけ結果を反転しています。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `interact_switch_component` | インタラクトのたびに ON / OFF を切り替え、`switch_changed_event` を `SendDown` | `basic_interactable_component` とメッシュがある entity | `StartOn` |
| `interact_hold_component` | 長押しの押し始め / 完了 / 中断で色を塗り分け、完了時に秒数を Print して `switch_changed_event{On := true}` を `SendDown` | `basic_interactable_component`（Interact Duration > 0）と SM_TutorialCube がある entity | `IdleColor` `HoldColor` `DoneColor` |
| `switch_light_component` | 同じ entity の `light_component` を点ける / 消す | スイッチの子孫（ライトと同じ entity） | `Invert` |
| `switch_enable_component` | 同じ entity の `enableable` なコンポーネントを全部まとめて ON / OFF | スイッチの子孫 | `Invert` |
| `switch_keyframe_component` | 同じ entity の `keyframed_movement_component` を `Play` / `Pause` | スイッチの子孫（`keyframe_loop_component` の `PlayOnStart` は false） | `Invert` |

イベント：`switch_changed_event`（`Switch`：送り元のスイッチの entity、`On`）

## イベントの流れ

```
プレイヤーがインタラクト（SucceededEvent）
  → interact_switch_component：On を反転
  → SendDown(switch_changed_event)
      → SwitchLamp：switch_light_component → Light.Enable / Disable
      → SwitchLift：switch_keyframe_component → Movement.Play / Pause

長押し（Interact Duration > 0）の場合

プレイヤーが押し始める（StartedEvent）
  → interact_hold_component：時刻を記録、HoldColor に塗る
  → 押し続けて完了（SucceededEvent）
      → 経過秒数を Print、DoneColor に塗る
      → SendDown(switch_changed_event{On := true}) → 子孫の switch_*_component が反応
  → 途中で離す（CanceledEvent）
      → IdleColor に戻す
```

## レベルでの置き場所

エリア中心 (0, 4000)（EnableSystem と同じエリア）。

- `SwitchSample`：スイッチ。子に `SwitchLamp`（ライト）と `SwitchLift`（キーフレームで動く床）
- `VariantSwitchEnable`：`switch_enable_component` で子の見た目ごと出したり消したりする例

## 試してみよう

1. `SwitchLamp` の `Invert` を true にする。スイッチ ON で消え、OFF で点くようになります。
2. `SwitchSample` の子に新しい entity を作り、ライトと `switch_light_component` を付ける。Verse を触らずに灯りを増やせます。
3. `SwitchLamp` の `switch_light_component` を `switch_enable_component` に替える。ライトだけでなくメッシュなど全部が一緒に ON / OFF されます。
4. `StartOn` を true にして、開始時の状態を変える。
5. `interact_hold_component` を付けた entity の `basic_interactable_component` の Interact Duration を 2 秒にする。押し始めで色が変わり、完了時に Print される秒数がほぼ 2 になります。途中で離すと元の色に戻ります。

## UE5 との違い

- UE5 ではスイッチ側がライトやドアへの参照を持って直接呼ぶことが多いですが、ここではスイッチは参照を持たず、子にするだけでつながります。
