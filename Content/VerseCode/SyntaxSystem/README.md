# SyntaxSystem

Verse の並行処理の書き方（`race` / `sync` / `defer`）と、失敗コンテキストを使った `for` のフィルターを、色が変わるキューブで体験するサンプルです。

## 見どころ

- **race**：`race_timer_component` は「プレイヤーが入った」と「時間切れ」を競わせ、先に終わった方の結果（`logic`）を使います。負けた方は自動でキャンセルされます。
- **sync**：`sync_gate_component` は 2 つの床スイッチの待ちを同時に進め、両方終わったら次へ進みます（どちらが先でもよい）。
- **defer**：`race_timer_component` は終わるとき（キャンセルされたとき）に `defer` でグレーに戻します。
- **出入りの検知は detector に任せる**：どちらも ZoneSystem の `volume_detector_component` を使います（継承はしない）。`race_timer_component` は `OnSimulate` で同じ entity の detector を取り、その `PlayerEnteredEvent.Await()` で「入った」を待ちます。`sync_gate_component` は子の床スイッチの detector が `SendUp` する `volume_entered_event` を `OnReceive` で受け、`Volume` が子 entity なら内部の event を `Signal` し、`OnSimulate` 側で床スイッチ A / B ごとに待ちます（`OnReceive` では待てないため）。
- **for の失敗フィルター**：`for (Child : Entity.GetEntities(), Child.GetComponent[volume_detector_component])` で、detector を持つ子だけが配列に入ります。
- **共通の部品**：`SyntaxPaint.verse` に、色の定数（待機・待ち・成功・失敗）をまとめています。塗るのは UtilitySystem の `PaintCube` です。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `race_timer_component` | 黄色のあいだ（`TimeLimit` 秒）に入れたら緑、間に合わなければ赤 | `SM_TutorialVolumeCube`（OverlapAll）・`volume_detector_component` と同じ entity | `TimeLimit`, `ResultTime` |
| `sync_gate_component` | 子の床スイッチ 2 つの両方に誰かが入ったら、自分のキューブを緑にする | `SM_TutorialCube` か `SM_TutorialVolumeCube` と同じ entity（子 entity 2 つに `SM_TutorialVolumeCube` と `volume_detector_component`） | `OpenTime` |

## イベントの流れ

```
race_timer_component：loop {
  黄色 → race { 入った → true / Sleep(TimeLimit) → false }
  → true なら緑・false なら赤 → Sleep(ResultTime)
}（終了時 defer でグレー）

sync_gate_component：loop {
  ゲートをグレー、床スイッチ A / B を黄色
  → sync { A に入る → A を緑 / B に入る → B を緑 }
     （OnReceive：子の volume_entered_event → PadEnteredEvent.Signal(Volume)、各 block は Volume が自分の床スイッチになるまで待つ）
  → ゲートを緑 → Sleep(OpenTime)
}
```

## レベルでの置き場所

エリア中心 (-4000, -4000)（JsonSystem と同じエリア）。

- `RaceTimerSample`：制限時間内に入るキューブ
- `VariantRaceTimerShort`：`TimeLimit` を短くした例
- `SyncGateSample`：子に床スイッチを 2 つ持つゲート

`RaceTimerSample` / `VariantRaceTimerShort` と、`SyncGateSample` の子の床スイッチ（`SyncPadA` / `SyncPadB`）には、それぞれ `volume_detector_component` を付けます。ゲート本体には付けません。

## 試してみよう

1. `RaceTimerSample` の `TimeLimit` を 2.0 にして、間に合うか試す。
2. `SyncGateSample` の床スイッチに 1 人で順番に入る。どちらを先に踏んでも、両方そろった時点でゲートが緑になります。
3. `SyncGateSample` の子の床スイッチを 1 つ消す。「子 entity 2 つに volume_detector_component が必要です」と出て動きません。
4. `race` を `sync` に書き換えたらどうなるか考えてみる（入っても時間切れまで待つことになります）。

## UE5 との違い

- UE5 の Blueprint では Delay や Latent ノード、Timer で非同期を表しますが、Verse では `race` / `sync` / `branch` / `spawn` で並行処理を構文として書けます。キャンセルも言語が面倒を見ます。
