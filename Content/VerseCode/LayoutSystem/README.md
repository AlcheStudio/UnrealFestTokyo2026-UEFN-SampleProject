# LayoutSystem

展示の各エリアの床（区切りのプレート）と、会場全体の見せ方をまとめたシステムです。床を色で塗る、今いるエリアの名前を右中央に出す、要らない標準 HUD を隠す、の 3 つを持ちます。

## 見どころ

- **親子と SendUp の見本**：エリアの床はすべて `AreaRoot` の子です。床の `area_label_component` が「入った / 出た」を `area_entered_event` / `area_exited_event` として親へ SendUp し、親の `area_name_hud_component` が受けてプレイヤーの画面を変えます。床と HUD はお互いを知らず、床を増やしても HUD 側は変わりません。
- **検知は共通部品に任せる**：床の出入りは ZoneSystem の `volume_detector_component` が調べ、`area_label_component` はその `volume_entered_event` を言い換えるだけです。自分では重なりを調べません。
- **Print はエリアにいる人にだけ**：床に `print_area_component` を置いているので、各展示の `AreaPrint` はそのエリアに誰かがいるあいだだけ出ます。
- **マテリアルのパラメーターを Verse から設定**：床専用のマテリアル `M_TutorialAreaFloor`（半透明の面・光る縁・マス目）を `M_TutorialAreaFloor{}` で作り、`Color` / `Glow` / `Opacity` / `GridCount` を入れてからメッシュの `BodyMat` に設定します。
- **HUD はプレイヤー単位で隠す**：`hud_cleanup_component` は島全体の設定ではなく `HideElementsForPlayer` を使い、終わるときは自分が隠した人だけ戻します。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `area_floor_component` | 開始時に床のプレートを `M_TutorialAreaFloor` で塗る | `SM_TutorialAreaFloor` と同じ entity | `FloorColor`, `Glow`, `Opacity`（0 で透明〜1 で不透明）, `GridCount`（一辺あたりのマス目の数） |
| `area_label_component` | 同じ entity の `volume_entered_event` / `volume_exited_event` を `area_entered_event` / `area_exited_event` に言い換えて親へ SendUp する。`Contains[Player]` で「その人がこのエリアにいるか」も答える | 床の entity（`volume_detector_component` と同じ entity） | `AreaName`（右中央に出す名前）、`Summary`（案内役の NPC が話すエリアの紹介） |
| `area_name_hud_component` | 子孫の床からの `area_entered_event` / `area_exited_event` を受けて、そのプレイヤーの画面の右中央に「今いるエリアの名前」を出す | 床をすべて子に持つ entity（`AreaRoot`） | `TextSize`, `Margin`, `TextColor` |
| `hud_cleanup_component` | 展示に要らない標準 HUD（ミニマップ・建築・チーム情報・ラウンド・経験値）をプレイヤーごとに隠す。体力、インタラクトの案内、手持ちのアイテム欄は残す | 会場に 1 つ（`BoothHud`） | `HideHealth`, `HideMinimap`, `HideBuild`, `HideTeamInfo`, `HideRoundInfo`, `HideExperience`, `HidePickupStream` |

関数：`(Simulation).FindAreaOf[Player]` は、その人が今いるエリアの `area_label_component` を世界から探します（床の子孫でない entity、たとえば案内役の NPC が使う）。

床の entity には、ZoneSystem の `volume_detector_component`（`HeightMargin` 300。薄い床なので上下の余裕を広げる）と `print_area_component`（`Radius` 2600、広場は 1700）も付いています。

## イベントの流れ

```
床の entity（AreaRoot の子）
  volume_detector_component ─ SendUp ─▶ volume_entered_event / volume_exited_event
  area_label_component       ─ OnReceive（Volume = 自分の entity のときだけ）
                             ─ SendUp ─▶ area_entered_event / area_exited_event
AreaRoot
  area_name_hud_component    ─ OnReceive ─▶ そのプレイヤーの右中央の文字を書き換える / 消す
                               （隣のエリアに先に入っていたら、出た知らせでは消さない）

BoothHud
  hud_cleanup_component      ─ OnSimulate ─▶ いる全員に HideElementsForPlayer、あとから入った人にも同じ
                             ─ OnEndSimulation ─▶ 自分が隠した人だけ ResetElementsForPlayer
```

どのイベントも消費しません（`OnReceive` は `false` を返す）。

## レベルでの置き場所

- `AreaRoot`（原点）：`area_name_hud_component`。子に `AreaFloor<Name>` の床 17 枚（広場の `AreaFloorPlaza` を含む）
- 各 `AreaFloor<Name>`：`SM_TutorialAreaFloor`、`area_floor_component`、`volume_detector_component`、`print_area_component`、`area_label_component`
- `BoothHud`（原点の少し左）：`hud_cleanup_component`
- プレートは床とのちらつき（Z ファイティング）を避けるため、少しだけ浮かせて薄くしてあります。

## 試してみよう

1. どれかのエリアへ歩いて入る。右中央にそのエリアの名前が出て、出ると消えます。
2. `AreaFloor*` の `area_label_component` の `AreaName` を変える。右中央の文字が変わります（Verse はそのまま）。
3. `AreaRoot` から `area_name_hud_component` を外す。床は変わらず SendUp しますが、受け手がいないので何も出ません。
4. `BoothHud` の `HideMinimap` をオフにして、ミニマップだけ戻す。
5. `AreaFloor*` の `FloorColor` / `Opacity` / `GridCount` を変えて、床の見た目を比べる。

## UE5 との違い

- UE5 では Dynamic Material Instance を作って `SetVectorParameterValue` などで名前を文字列で指定しますが、ここでは UEFN が生成したマテリアルのクラス（`M_TutorialAreaFloor`）のフィールドに型付きで値を入れます。
- UE5 なら「エリアに入った」を Actor の Overlap イベントで受け、HUD を Blueprint のイベントディスパッチャーなどで更新します。ここでは床の component が親へ `SendUp` し、親の component が `OnReceive` で受けるだけで、床と HUD の参照関係はありません。
