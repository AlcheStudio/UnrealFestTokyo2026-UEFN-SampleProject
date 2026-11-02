# TimerSystem

自前の `Sleep` ループではなく、標準の `timer`（`playable` インターフェース）でカウントダウンを作るサンプルです。プレイヤーがゾーンに入るとカウントダウンが始まり、全員出ると一時停止、また入ると再開します。

> **注意**：`timer` / `playable` / `clock` は `@experimental` の API です。実験的機能を使ったプロジェクトは公開（パブリッシュ）できない場合があります。学習用として試し、公開する島では `Sleep` ベースのタイマーに置き換えてください。

## 見どころ

- **timer は playable**：`Play` / `Pause` / `Resume` / `Stop` が最初から揃っています。`Sleep` ループで一時停止を作ると「残り時間を自分で引き算して覚えておく」必要がありますが、`timer` なら `Pause()` と `Resume()` を呼ぶだけです。
- **clock から時間をもらう**：`timer` は `ReferenceClock`（ここでは `SecondsSinceEpochClock`）を元に `StartSeconds` から `EndSeconds` へ進みます。`PlayRate` を変えると倍速・スローになります。
- **終了は StopEvent で待つ**：`StopEvent.Await()` は `playable_stop_reason` を返すので、自然に終わった（`Finished`）のか `Stop()` で止められた（`Explicit`）のかを区別できます。
- **race で 3 つを並べる**：「終了を待つ」「出入りを見張って Pause / Resume する」「1 秒ごとに残り秒数を Print する」を `race` に並べ、終了したら残りは自動でキャンセルされます。
- **volume_detector_component の使い方**：継承はせず、`OnSimulate` で同じ entity の detector を `GetComponent` で取り、その `PlayerEnteredEvent` / `PlayerExitedEvent` / `InsideCount()` だけで出入りを扱います。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `countdown_timer_component` | 最初のプレイヤーが入ったら `Seconds` 秒のカウントダウンを始め、全員出たら一時停止、再入場で再開。終わったら `DoneColor` に塗って 2 秒後に待ち状態へ戻る | `SM_TutorialVolumeCube`（OverlapAll）・`volume_detector_component` と同じ entity | `Seconds`, `PlayRate`, `IdleColor`, `RunningColor`, `DoneColor` |

## イベントの流れ

```
プレイヤーがキューブに入る
  → volume_detector_component：PlayerEnteredEvent.Signal
      → countdown_timer_component（OnSimulate で Await）：timer を作って Play、RunningColor に塗る
          race:
            StopEvent.Await()        … 終了（Finished）か Stop（Explicit）を待つ
            WatchOccupancy           … 全員出たら Pause、誰か入ったら Resume
            ReportRemaining          … 1 秒ごとに残り秒数を Print
  → 終了：DoneColor に塗って Print、2 秒後に IdleColor へ戻って次の入場を待つ
  → シミュレーション終了：OnEndSimulation で timer を Stop する
```

## レベルでの置き場所

未配置。OverlapAll のメッシュ（SM_TutorialVolumeCube）と `volume_detector_component` を持つ entity に付ける。

## 試してみよう

1. キューブに入って、1 秒ごとの「残り n 秒」の Print と、終了時に `DoneColor` へ変わることを確かめる。
2. カウントダウン中にキューブから出て、Print が止まる（一時停止する）こと、戻ると続きから再開することを確かめる。
3. `PlayRate` を `2.0` にして倍速に、`0.5` にしてスローになることを確かめる。
4. 2 人で入り、1 人だけ出てもタイマーが止まらないこと（detector の `InsideCount() = 0` のときだけ Pause する）を確かめる。
5. `StartSeconds` と `EndSeconds` を入れ替えたら `GetSeconds()` がどう変わるか試してみる。

## UE5 との違い

- UE5 では `FTimerManager`（`SetTimer` / `PauseTimer` / `UnPauseTimer`）や Blueprint の Delay / Timeline でカウントダウンを作ります。Verse の `timer` は `clock` と `playable` を組み合わせた普通のオブジェクトで、`Await` できる `StopEvent` を持ち、`race` や `defer` といった Verse の並行処理の書き方と自然につながります。
- UE5 の Timer は World の時間（Tick）に結びついていますが、Verse の `timer` は `ReferenceClock` を差し替えられる設計で、どの時計を基準に進むかを自分で決めます。
