# QuestSystem

ゾーンに入ったプレイヤーに「○○を N 回する」クエストを渡し、達成するとコインをもらえるサンプルです。何をすれば進むかは派生コンポーネントの付け替えで決めます。

> **注意**：クエスト（Progression）とエンタイトルメントの API は実験的・プラットフォーム依存の機能です。環境によってはクエストに参加できず、ログに「クエストに参加できなかった」と出ます。

## 見どころ

- **抽象の基底＋派生**：`quest_giver_component` がクエストの作成・参加・ごほうびを受け持ち、派生は `TrackProgress`（何をしたら進むか）だけを書きます。ジャンプで進むか、しゃがみで進むかは付けるコンポーネントで選びます。
- **ほかのシステムの再利用**：入った人の検知は同じ entity の ZoneSystem の `volume_detector_component` に任せ（継承はせず、`volume_entered_event` を `OnReceive` で受ける）、ごほうびには MarketSystem の `tutorial_coin_entitlement` を使っています。クエストの種類ごとの派生（`jump_quest_component` など）は `quest_giver_component` を継承したままです。
- **Fortnite のクエスト画面に出る**：クエストの `Collection` に `fort_quest_collection` を渡すので、Fortnite のクエスト画面に表示されます。画面に出すには、クエストが `has_description`（名前・説明）と `has_icon`（アイコン）を実装している必要があります。
- **Verse の書き方**
  - `race` で「`TrackProgress` で数え続ける」と「`Quest.CompleteEvent` を待つ」を競わせ、達成したら数える方を自動でキャンセルします。
  - `[player]logic` の map で 1 人 1 つを管理し、`defer` で達成後に渡し直せるよう戻します。
  - `fort_character.CrouchedEvent()` はしゃがんだ / 立った両方で届くので、`Crouched(1)?` で「しゃがんだ」ときだけ数えます。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `quest_giver_component`（抽象・直接は付けない） | 入った人にクエストを渡す（1 人 1 つ、達成までは渡し直さない）。達成でコイン 1 枚 | — | `Title`, `Description`, `RequiredCount` |
| └ `jump_quest_component` | ジャンプした回数で進む（`JumpedEvent`） | OverlapAll のメッシュ・`volume_detector_component` と同じ entity | 基底の分 |
| └ `crouch_quest_component` | しゃがんだ回数で進む（`CrouchedEvent`） | OverlapAll のメッシュ・`volume_detector_component` と同じ entity | 基底の分 |

## イベントの流れ

```
プレイヤーがゾーンに入る
  → volume_detector_component：SendUp(volume_entered_event)
  → quest_giver_component.OnReceive（Volume = Entity）→ spawn{GiveQuest}
      → progress_objective（RequiredProgress = RequiredCount）＋ entitlement_quest_reward（コイン 1 枚）で tutorial_quest を作る（Collection = fort_quest_collection）
      → Quest.Join（agent_quest_participant）→ Quest.Activate
      → race { TrackProgress（派生が SetProgress）/ Quest.CompleteEvent }
      → 達成 → ごほうびのコイン
```

## レベルでの置き場所

エリア中心 (0, 8000)。

- `QuestJump`：ジャンプのクエストを渡すゾーン
- `QuestCrouch`：しゃがみのクエストを渡すゾーン

## 試してみよう

1. `QuestJump` に入り、`RequiredCount` の回数だけジャンプする。クエスト画面で進み具合が見え、達成するとコインがもらえます。
2. `RequiredCount` を 2 にして、すぐ達成できるようにする。`Title` / `Description` も書き換えてクエスト画面の表示を確かめる。
3. `QuestJump` の `jump_quest_component` を `crouch_quest_component` に替える。同じゾーンがしゃがみのクエストになります。
4. もらったコインを MarketSystem の `MarketConsumePad` で使ってみる。

## UE5 との違い

- UE5 にはクエストの標準の仕組みが無く、進行・報酬・UI を自分で作ります。UEFN では `quest` / `objective` / `quest_reward` の型と、Fortnite のクエスト画面が用意されていて、Verse はそれに乗せるだけです。
- 進み具合は `progress_objective.SetProgress` に数を入れるだけで、達成の判定と報酬の付与は仕組み側が行います。
