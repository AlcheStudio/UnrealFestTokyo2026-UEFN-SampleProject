# GameLoopSystem

入口に入ったプレイヤーを挑戦者にして、「段階（step）」を順に動かすミニゲームの仕組みです。段階・失敗条件・渡す武器・NPC は、どれもループの直下の entity にコンポーネントを付けて組み合わせます。Verse を変えずに、付ける段階を差し替えるだけで別のゲームになります。

## 見どころ

- **モジュール化（抽象の基底＋キット）**
  - `game_step_component`（段階）→ `StepKit`：カウントダウン / NPC を倒す / 結果 / 出口
  - `game_fail_component`（失敗条件）→ `FailKit`：倒されたら失敗
  - `game_item_grant_component`（武器を渡す）→ `GrantKit`：ライフル / 剣 / ハンマー
  - 順番は各段階の `Order`（小さい順）。enum や @editable の配列ではなく、「直下の entity に何が付いているか」でゲームが決まります。
- **scene_event の両方向**
  - 入口 → ループ：`game_join_event` を `SendUp`
  - ループ → 子孫：`game_started_event` / `game_ended_event` / `game_center_text_event` / `game_status_text_event` を `SendDown`。HUD・武器・NPC スポナーがそれぞれ受け取ります。
- **並行処理**
  - `race`：「段階を進める」と「失敗を待つ」、「ゲーム本体」と「挑戦者が抜けた」を競わせ、負けた方は自動でキャンセル。
  - `defer`：どう終わっても（クリア・失敗・離脱）文字を消し、`game_ended_event` を流して挑戦者を空けます。
  - `branch`：NPC を倒す段階で、始めの文字を消すタイマーを裏で動かします。
- **参照を持たないつながり**：NPC の振る舞いはデバイスへの参照を持たず、`game_defeat_target_tag` の付いた段階をタグで探して `NotifyDefeated` を呼びます。

## component 一覧

### 本体

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `game_loop_component` | `game_join_event` を受けて挑戦者を決め、直下の段階を `Order` の順に動かす。開始・終了・画面の文字を `SendDown`。クリア秒数を持つ | ゲームの親 entity（ゲーム 1 つに 1 つ） | なし |
| `game_entrance_component` | プレイヤーが入ったら `game_join_event` を `SendUp`（検知は同じ entity の ZoneSystem の `volume_detector_component`。その `volume_entered_event` を `OnReceive` で受ける） | ループの直下（同じ entity に OverlapAll のメッシュと `volume_detector_component`） | なし（`PollInterval` は detector） |
| `game_hud_component` | 挑戦者の画面に真ん中の文字と上の状態の文字を出す | ループの直下 | `CenterSize`, `StatusSize` |

### 段階（StepKit）

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `game_step_component`（抽象・直接は付けない） | 1 段階の基底。`RunStep` が戻ったら次へ | — | `Order` |
| └ `countdown_step_component` | `Seconds` から 1 まで数えて `GoText` を出す | ループの直下 | `Seconds`, `GoText`（＋`Order`） |
| └ `defeat_npc_step_component` | `IntroText` を出し、残り人数を表示しながら `TargetCount` 体倒されるまで待つ。かかった秒数を記録 | ループの直下（レベルに 1 つ） | `TargetCount`, `IntroText`, `IntroTime` |
| └ `result_step_component` | 記録した秒数を「○.○ 秒で倒した！」のように出す | ループの直下（倒す段階より後の `Order`） | `Suffix`, `ShowTime` |
| └ `exit_step_component` | `Text` を出して `Delay` 秒後、挑戦者を子 entity の位置へテレポート | ループの直下（子に出口の entity を 1 つ） | `Text`, `Delay` |

### 失敗条件（FailKit）・武器（GrantKit）

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `game_fail_component`（抽象・直接は付けない） | 失敗条件の基底。`AwaitFail` が戻ったら失敗 | — | `FailText`, `ShowTime` |
| └ `fail_on_eliminated_component` | 挑戦者が倒されたら失敗 | ループの直下（ゲームに 1 つまで） | 基底の分 |
| `game_item_grant_component`（抽象・直接は付けない） | 開始時に挑戦者の武器ホットバーへ 1 つ入れ、終了時に回収する基底 | — | `RemoveOnEnd` |
| └ `grant_assault_rifle_component` | アサルトライフル（レア）を渡す | ループの直下（1 entity に 1 つ） | `RemoveOnEnd` |
| └ `grant_sword_component` | 剣を渡す | 同上 | `RemoveOnEnd` |
| └ `grant_hammer_component` | ハンマーを渡す | 同上 | `RemoveOnEnd` |

### NPC（NpcKit）

| 名前 | 役割 | 置き方 | 主な @editable |
|---|---|---|---|
| `game_npc_spawner_component` | 開始で NPC スポナーを `Reset` → `Enable`、終了で `Disable` → `DespawnAll` | ループの直下。`Spawner` に NPC スポナーデバイスを入れる | `Spawner` |
| `game_npc_behavior`（`npc_behavior`） | 倒す段階が動いているあいだは挑戦者を追って攻撃、それ以外はうろつく。倒されたら段階に知らせる | NPC のキャラクター定義の振る舞いに指定（ガードの種類） | `ChaseRadius`, `ThinkInterval` |

NPC スポナーの前提：「ゲーム開始時に有効」はオフ、「有効になったらスポーン」と「無効で NPC を消す」はオン。

## イベントの流れ

```
プレイヤーが入口へ
  → game_entrance_component：SendUp(game_join_event)
  → game_loop_component：挑戦者に設定 → SendDown(game_started_event)
        → game_hud_component：画面を出す
        → grant_*：武器をホットバーへ
        → game_npc_spawner_component：スポナー Enable
  → race {
        段階を Order 順に RunStep：countdown → defeat_npc → result → exit
          （段階は Loop.ShowCenter / ShowStatus → SendDown(game_*_text_event) → HUD）
        fail_on_eliminated_component.AwaitFail（倒されたら FailText を出して終了）
     } と、さらに「挑戦者が抜けた」との race
  → defer：文字を消す → SendDown(game_ended_event)
        → HUD を消す / 武器を回収 / スポナー Disable・NPC を消す

NPC（game_npc_behavior）が倒される
  → タグ game_defeat_target_tag で defeat_npc_step_component を探す → NotifyDefeated
```

## レベルでの置き場所

エリア中心 (8000, 0)。

- `GameLoop`：フル版。カウントダウン → NPC を 3 体倒す → 結果 → 出口。NPC スポナーデバイスを使います。
  - **注意**：`game_npc_spawner_component` の `Spawner` には、エディターで NPC スポナーデバイスを手で設定してください（未設定だと NPC が出ません）。
- `GameLoopQuick`：簡易版。剣を渡し、カウントダウン → 出口だけ。

## 試してみよう

1. `GameLoopQuick` の剣の entity の `grant_sword_component` を `grant_hammer_component` に替える。渡される武器が変わります。
2. `GameLoop` の `countdown_step_component` の `Seconds` を 5 に、`GoText` を好きな言葉に変える。
3. `GameLoopQuick` の直下に entity を足して `countdown_step_component` をもう 1 つ付ける（`Order` を重ねない）。カウントダウンが 2 回になります。段階の順番は `Order` を入れ替えるだけで変わります。
4. `GameLoop` の `fail_on_eliminated_component` を外す。倒されてもゲームが失敗しなくなります。`defeat_npc_step_component` の `TargetCount` を 1 にすると短く遊べます。

## UE5 との違い

- UE5 の GameMode / GameState にゲームの流れを書く代わりに、ゲームを 1 つの entity ツリーにまとめ、段階をコンポーネントとして並べています。同じレベルに複数のゲーム（`GameLoop` と `GameLoopQuick`）を独立して置けます。
- NPC は AIController＋Behavior Tree ではなく、キャラクター定義に指定した Verse の `npc_behavior` で動かします。
- HUD は UMG の Widget Blueprint ではなく、Verse で `canvas` と `text_block` を組み立てて `player_ui` に足しています。
