# EventSystem

自前の `event(int)` を `Subscribe` で受け取る書き方と、`PlayerEnteredEvent` を `Await` するループで受け取る書き方を、同じ ZoneSystem の `volume_detector_component`（出入りの検知）を使って並べて見せるチュートリアルです。あわせて `SecondsSinceEpochClock` で現在時刻（エポック秒）を読みます。

## 見どころ

- **自前の event に Subscribe**：`event(t)` が `listenable(t)` になったので、`CountChangedEvent.Subscribe(OnCountChanged)` とコールバックを登録できます。`Signal` と同じフレームで同期的に呼ばれ、`<suspends>` のループを書く必要がありません。
- **cancelable の後始末**：`Subscribe` が返す `cancelable` を `?cancelable` に持ち、`OnEndSimulation` で `Cancel()` してから `(super:)OnEndSimulation()` を呼びます。
- **入場の受け取り方も 2 通り**：`event_counter_component` は detector が `SendUp` する `volume_entered_event` を `OnReceive` で受け取ります。`event_clock_component` は `OnSimulate` で同じ entity の detector を `GetComponent` で取り、その `PlayerEnteredEvent.Await()` を `loop` で待つ従来の書き方です。どちらも継承はしません。
- **clock**：`SecondsSinceEpochClock.GetSeconds()` で 1970 年からの秒数（float）が取れます。前回との差を取れば経過秒になります。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `event_counter_component` | 入るたびに数を増やして `CountChangedEvent` を `Signal`。自分で `Subscribe` した `OnCountChanged` がキューブを塗り直して Print する | OverlapAll のキューブ・`volume_detector_component` と同じ entity | `Goal`, `IdleColor`, `GoalColor` |
| `event_clock_component` | `PlayerEnteredEvent.Await()` のループで入場を受け取り、エポック秒と前回からの経過秒を Print する | OverlapAll のキューブ・`volume_detector_component` と同じ entity | なし（`PollInterval` は detector） |

イベント：`CountChangedEvent:listenable(int)`（新しい数。非公開の `event(int)` を `MakeProxyListenable` で包んだもので、外のコンポーネントからも `Subscribe` / `Await` できるが `Signal` はできない）

## イベントの流れ

```
プレイヤーがキューブに入る
  → volume_detector_component：SendUp(volume_entered_event) と PlayerEnteredEvent.Signal(Player)
      → event_counter_component：OnReceive（Volume = Entity）で Count += 1 → CountChangedEvent.Signal(Count)
          → Subscribe しておいた OnCountChanged(Count)（同じフレームで同期）
              → PaintCube(IdleColor / GoalColor)、Print
      → event_clock_component：OnSimulate の loop で Detector.PlayerEnteredEvent.Await() が返る
          → SecondsSinceEpochClock.GetSeconds() を Print、前回との差を Print
```

## レベルでの置き場所

未配置。OverlapAll のメッシュ（SM_TutorialVolumeCube）と `volume_detector_component` を持つ entity に付ける。

## 試してみよう

1. `event_counter_component` を付けたキューブに出入りを繰り返し、`Goal` 回目で色が `GoalColor` に変わることを確かめる。
2. `Goal` を 1 にして、最初の入場で色が変わるようにする。
3. `event_clock_component` を同じ entity に付け、入るたびに Print されるエポック秒と経過秒を見る。
4. `event_counter_component` の `Subscribe` を消して、代わりに `OnSimulate` の `CountChangedEvent.Await()` のループで同じことを書いてみる（`event_clock_component` と同じ形になる）。

## UE5 との違い

- UE5 では Dynamic Multicast Delegate に `AddDynamic` でバインドし、`RemoveDynamic` で外します。Verse の `event(t)` は `Subscribe` が返す `cancelable` を `Cancel()` するだけで外れ、同じイベントを `Await` で待つこともできます。
- UE5 の `FDateTime::UtcNow()` にあたるものが `SecondsSinceEpochClock`。秒数の float 1 つで返るので、差を取るだけで経過時間になります。
