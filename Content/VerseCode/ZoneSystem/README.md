# ZoneSystem

プレイヤーがゾーンに入った / 出たときに何かをするサンプルです。出入りの検知は `volume_detector_component` の 1 か所だけにまとめ、何をするかは同じ entity に並べた受け取り側のコンポーネントを付け替えて決めます。継承は使いません（has-a ＋ scene_event）。

> **注意**：ゾーンのメッシュは **OverlapAll**（`SM_TutorialVolumeCube` か `SM_TutorialCylinder`）にしてください。BlockAll のメッシュだとプレイヤーが中に入れません。
>
> **注意**：出入りを使う entity には、必ず **`volume_detector_component`** も付けてください。付け忘れると、受け取り側のコンポーネントが開始時に「同じ entity に volume_detector_component がありません」と Print し、出入りに反応しません。ほかの System（Market / Quest / Cylinder / Camera / Ability / GameLoop / Syntax / Timer / Event / Health）のボリュームも同じです。

## 見どころ

- **検知は 1 か所、使う側は has-a**：`volume_detector_component` が出入りを調べ、プレイヤー（`fort_character` を持ち、agent が `player`）だけを通して知らせます。受け取り側は `class<final_super>(component)` の普通のコンポーネントで、検知のために何かを継承することはありません。同じ entity に detector と並べて置くだけです。
- **知らせ方は 2 通り**
  - **scene_event**：detector は自分の entity から `volume_entered_event` / `volume_exited_event` を `SendUp` します。同じ entity と祖先のコンポーネントの `OnReceive` に届きます。中身は `Player`、`Character`、`Volume`（送り元のボリュームの entity）。受け取り側は `Volume = Entity` で「自分の entity のボリュームの知らせか」を見分け、`false` を返して消費しません（親にも届き続けるようにするため）。
  - **listenable**：待ちやループを書きたいときは、`OnSimulate` で `Entity.GetComponent[volume_detector_component]` を取り、`PlayerEnteredEvent` / `PlayerExitedEvent` を `Await` します。
- **検知は 2 本立て**：`PollInterval` 秒ごとに、`FindOverlapHits` で「今重なっている entity」を問い合わせるのに加えて、プレイヤーの位置がメッシュの範囲（100cm の箱 × Scale。`SM_TutorialCylinder` なら円柱）に入っているかも調べます。どちらかで見つかれば「中にいる」とし、変わったときだけ知らせるので、同じプレイヤーを二重に数えません。
- **状態も読める**：`GetPlayersInside`、`InsideCount`、`IsInside`、`FindCharacterEntity`、`WaitUntilLeft` で、いま中にいる人を読めます。`FindCharacterEntity` は問い合わせで見つかった人のキャラクター entity だけを返す（位置で見つかった人や、出たあとの人は失敗する）ので、入った知らせを受けたその場で使います。
- **終わるときも出た扱い**：detector が終わるときは、まだ中にいる人ぶんの `volume_exited_event` と `PlayerExitedEvent` を送ってから片付けます。`ghost_zone_component` のように「出たら元に戻す」反応は、何もしなくても後始末されます。
- **公開イベントの形**：`PlayerEnteredEvent` / `PlayerExitedEvent` は、非公開の `event(player)` を `MakeProxyListenable` で包んだ `listenable(player)` です。外から `Await` / `Subscribe` はできますが `Signal` はできません（Epic の標準 component と同じ形）。
- **ほかのシステムからも使われる**：MarketSystem のパッド、QuestSystem のクエスト、CylinderSystem のシリンダー、CameraSystem のカメラゾーン、AbilitySystem のパッド、GameLoopSystem の入口、SyntaxSystem のキューブと床スイッチ、TimerSystem のカウントダウン、EventSystem、HealthSystem のダメージゾーン、LayoutSystem のエリアの床、PrintArea のエリアも、すべて同じ `volume_detector_component` を使っています。
- **Verse の書き方**
  - `OnReceive` は `<suspends>` ではないので待てません。時間のかかる処理は `spawn{}` で別の流れにするか、`event` を `Signal` して `OnSimulate` 側で待ちます（SyntaxSystem の `sync_gate_component`）。
  - `TeleportTo[]` は失敗しうる関数。`not` の中で呼ぶと成功しても取り消されるので、UtilitySystem の `TryTeleport` が `logic{}` で結果だけを受け取ります。
  - `input_method_zone_component` は `case` で `input_method` ごとに案内文を選びます（`_` はそれ以外）。
  - `stasis_zone_component` は `spawn{}` で「`Duration` 秒後に解除」を別の流れで動かします。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `volume_detector_component` | プレイヤーの出入りを調べ、`volume_entered_event` / `volume_exited_event` を `SendUp`、`PlayerEnteredEvent` / `PlayerExitedEvent` を鳴らす | OverlapAll のメッシュと同じ entity | `PollInterval`, `HeightMargin`（位置で調べるときの上下の余裕。薄い床なら 300） |
| `stasis_zone_component` | 入った人を `Duration` 秒その場に固める（向きは変えられる） | メッシュ・`volume_detector_component` と同じ entity | `Duration` |
| `ghost_zone_component` | 入っているあいだ透明にしてダメージを受けなくする。出たら戻す | 同上 | なし |
| `random_teleport_zone_component` | 入った人をまわりのランダムな場所（`MinRadius`〜`Radius`）へ移す | 同上 | `Radius`, `MinRadius` |
| `input_method_zone_component` | 入った人の操作方法（キーボードとマウス / ゲームパッド / タッチ）に合わせた案内を Print | 同上 | なし |
| `print_area_component` | 誰かがいるあいだだけ、範囲（`Radius`）の中の entity の `AreaPrint` を通す。「誰かいるか」は同じ entity の detector の `InsideCount` で見る | 同上 | `Radius` |

イベント：`volume_entered_event` / `volume_exited_event`（`Player`、`Character`、`Volume`：送り元のボリュームの entity）。向きは `SendUp`、消費しない。

## イベントの流れ

```
プレイヤーがゾーンに入る（PollInterval ごとの FindOverlapHits、または位置の判定）
  → volume_detector_component：player か確かめ、まだ中にいない人なら
      → SendUp(volume_entered_event{Player, Character, Volume := 自分の entity})
          → 同じ entity の受け取り側：Volume = Entity なら反応（固める / 透明 / テレポート / 案内）、false を返す
          → 親 entity の受け取り側へ…（親でまとめて受けるときは Volume で見分ける）
      → PlayerEnteredEvent.Signal(Player)（OnSimulate で Await している側が動く）
出る → SendUp(volume_exited_event) と PlayerExitedEvent（ghost なら元に戻す）
```

## レベルでの置き場所

エリア中心 (-8000, -8000)。

- `ZoneStasis`：入ると固まるゾーン
- `ZoneGhost`：入っているあいだ透明になるゾーン
- `ZoneTeleport`：入るとランダムな場所へ飛ばされるゾーン
- `ZoneInput`：操作方法に合わせた案内を出すゾーン

どのゾーンも、OverlapAll のメッシュ・`volume_detector_component`・効果のコンポーネントを同じ entity に並べます。

`print_area_component` は各展示エリアの床（LayoutSystem の `AreaFloor<Name>`、`AreaRoot` の子）に `volume_detector_component` と一緒に置いてあります。エリアに誰もいないあいだは、そのエリアの展示の `AreaPrint` は出ません。

## 試してみよう

1. `ZoneStasis` の `stasis_zone_component` を外して `random_teleport_zone_component` を付ける。detector はそのままで、同じゾーンがテレポートのゾーンになります。
2. `ZoneGhost` に `input_method_zone_component` も足す。1 つの detector の知らせが、並べた 2 つの反応の両方に届きます（どちらも `false` を返すため）。
3. `ZoneTeleport` の `Radius` / `MinRadius` を変えて、飛ばされる範囲を変える。
4. `ZoneGhost` のメッシュを、もう一方の OverlapAll のメッシュ（`SM_TutorialVolumeCube` ⇔ `SM_TutorialCylinder`）に替える。形が変わっても同じように動きます。
5. `ZoneInput` から `volume_detector_component` を外して始める。出力ログに付け忘れの Print が出て、入っても反応しないことを確かめる。

## UE5 との違い

- UE5 では Trigger Volume / Box Collision の `OnComponentBeginOverlap` を Blueprint で受けて、相手が Pawn かどうかを Cast で確かめます。ここではその共通部分を `volume_detector_component` 1 つにまとめ、反応は同じ entity に並べたコンポーネントが scene_event で受け取ります。基底クラスを継承して override する形にしないので、反応をいくつでも並べたり、付け替えたりできます。
