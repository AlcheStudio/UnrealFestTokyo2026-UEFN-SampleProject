# AbilitySystem

Verse で作ったアビリティ（`tutorial_ability`）をパッドで使い、「何が起きるか」を効果コンポーネントの付け替えだけで変えるサンプルです。

## 見どころ

- **モジュール化**：パッド（`ability_pad_component`）は「使った」ことを知らせるだけ。回復・ダメージ・打ち上げ・発光は、同じ entity（または子孫）に付けた効果コンポーネントが決めます。
- **scene_event**：パッドは `ability_used_event` を `SendDown` で流し、効果コンポーネントは `OnReceive` で受け取ります。どれも `false` を返す（消費しない）ので、効果を何個並べても全部に届きます。
- **Verse の書き方**
  - `ability(ability_context, ability_effect)` は型パラメーターを取るクラス。`MakeContext` / `MakeAbility` を override します。
  - `Use` は取り消せない処理なので、`if` の条件（失敗コンテキスト）の外で呼んでいます。
  - `OnReceive` は待てない（`<suspends>` でない）ので、`ability_glow_effect_component` は `spawn{}` で別の流れを起こして `Sleep` します。`defer` で `Glowing` と色を確実に戻し、終わるときは `StopSignal` で待ちを打ち切ります。
  - パッドは継承をせず、乗った人の検知は同じ entity の ZoneSystem の `volume_detector_component` に任せています。detector が `SendUp` する `volume_entered_event` を `OnReceive` で受け、乗った人のキャラクター entity は、イベントに入っている `Character` から `GetEntity[]` で取ります。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `ability_pad_component` | 乗ったプレイヤー（`volume_detector_component` が検知）を使い手としてアビリティを `Use` し、`ability_used_event` を `SendDown`。`Cooldown` 秒後に `Cancel` | パッドの entity（同じ entity に OverlapAll のメッシュと `volume_detector_component`） | `Cooldown` |
| `ability_heal_effect_component` | 使ったプレイヤーを回復 | パッドの entity か子孫 | `Amount` |
| `ability_damage_effect_component` | 使ったプレイヤーにダメージ | パッドの entity か子孫 | `Amount` |
| `ability_launch_effect_component` | 使ったプレイヤーを真上へ打ち上げる | パッドの entity か子孫 | `LaunchSpeed` |
| `ability_glow_effect_component` | 効果中はキューブを `ActiveColor`、終わったら `IdleColor` に塗る | `SM_TutorialCube` か `SM_TutorialVolumeCube` と同じ entity | `ActiveColor`, `IdleColor` |

イベント：`ability_used_event`（`Pad`：送り元のパッド、`Agent`：使った人、`Instigator`：使った entity、`Character`：使った人のキャラクター、`DurationSeconds`：効果の秒数 = `Cooldown`）

## イベントの流れ

```
プレイヤーがパッドに乗る
  → volume_detector_component：SendUp(volume_entered_event)
  → ability_pad_component（OnReceive、Volume = Entity）：CanUse → Use
  → SendDown(ability_used_event) ──→ heal / damage / launch / glow の各 effect
  → Sleep(Cooldown) → Cancel（アビリティ終了、また乗れる）
```

## レベルでの置き場所

エリア中心 (4000, -4000)。

- `AbilityHealPad`：回復のパッド
- `AbilityDamagePad`：ダメージのパッド
- `VariantAbilityLaunchPad`：打ち上げのパッド（効果を付け替えた例）

どのパッドの entity にも `volume_detector_component` を付けます。

## 試してみよう

1. `AbilityHealPad` の `ability_heal_effect_component` を外して `ability_launch_effect_component` を付ける。Verse を触らずに回復パッドが打ち上げパッドになります。
2. 1 つのパッドに `ability_damage_effect_component` と `ability_launch_effect_component` を並べて付ける。イベントは消費されないので、両方が同時に起きます。
3. `Cooldown` を 1.0 や 6.0 に変える。発光している時間と、次に使えるまでの時間が一緒に変わります。
4. `ability_glow_effect_component` を外す。効果はそのままで、色だけが変わらなくなります（見た目と効果が分かれていることの確認）。

## UE5 との違い

- UE5 の GAS（Gameplay Ability System）のように C++ / Blueprint でアビリティクラスと GameplayEffect を用意するのではなく、Verse のクラス 1 つ＋効果コンポーネントの組み合わせで表しています。
