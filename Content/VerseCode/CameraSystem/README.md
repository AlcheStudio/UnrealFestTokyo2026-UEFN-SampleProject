# CameraSystem

ゾーンに入ったプレイヤーのカメラを、ゾーンの子 entity に置いたカメラへ切り替えるサンプルです。カメラの種類や追い方は、子 entity のコンポーネントを付け替えて決めます。

## 見どころ

- **モジュール化**：`camera_zone_component` は「どのカメラか」を知りません。子 entity に付けたカメラコンポーネント（perspective / orthographic / physical）を使うだけです。追い方も `camera_follow_component` の派生を付け替えて変えます。
- **出入りの検知は detector に任せる**：ゾーンの entity に ZoneSystem の `volume_detector_component` を並べ、その `volume_entered_event` / `volume_exited_event` を `OnReceive` で受け取ります（継承はしない）。追従の対象（キャラクターの entity）は入った瞬間に detector の `FindCharacterEntity` で取り、分からないときは追従なしでカメラだけ切り替えます（1 回だけ Print）。
- **scene_event**：ゾーンは出入りを `camera_target_event` として `SendDown` し、子のカメラ側の `camera_*_follow_component` が受け取ってモディファイアーを積む / 外します。
- **director の 3 つの層**：プレイヤーの `camera_director_component` には `PreCameraModifiers` / `PostCameraModifiers` / `PresentationCameraModifiers` の 3 つのスタックがあります。Pre はどのカメラが選ばれるより前に走る層（カメラ全体で共通の初期値を入れる）、Post はカメラが決まりブレンドまで終わった結果に走る層（当たり判定や反動など、ブレンド中に何度も走らせたくないもの）、Presentation は見た目だけの仕上げの層（揺れなど。照準や移動方向には影響しない）。`camera_layer_bob_component` の派生（`camera_pre_bob_component` / `camera_post_bob_component` / `camera_presentation_bob_component`）が、それぞれの層に上下に揺れるモディファイアーを積みます。カメラ側の `CameraModifiers`（Main 層）に積む `camera_follow_component` との置き場所の違いが見どころです。
- **camera_modifier の自作**：`camera_bob_modifier` の `Evaluate` は `<reads>` なので時間を取れません。component が `OnSimulate` で毎フレーム `Offset` を入れ、`Evaluate` は `CloneCameraState` で元の状態をコピーして `RenderLocation` だけ差し替えます。
- **cancelable で後始末**：`AddCamera` / `AddModifier` の戻り値の `cancelable` をプレイヤーごとに map に覚えておき、出たら `Cancel` で外します。
- **Verse の書き方**：map から 1 件消す API がないので、`for (Key -> Value : Active, Key <> Target)` で残す分だけ新しい map を作っています（map への代入は失敗しうるので `option{}` で包む）。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `camera_zone_component` | 入ったプレイヤーの `camera_director_component` に子のカメラを `AddCamera`。出たら `Cancel`。出入りを `camera_target_event` で `SendDown` | ゾーンの entity（同じ entity に OverlapAll のメッシュと `volume_detector_component`、子 entity にカメラ） | `Priority` |
| `camera_follow_component`（抽象・直接は付けない） | プレイヤーごとにモディファイアーを積む / 外す基底。派生が `MakeModifier` を決める | — | — |
| └ `camera_fixed_angle_follow_component` | 決まった角度と距離から見下ろして追う（`fort_fixed_angle_camera_modifier`） | カメラを付けた子 entity | `CameraDistance`, `Pitch` |
| └ `camera_orbit_follow_component` | プレイヤーのまわりを回り込めるカメラ（`fort_orbit_camera_modifier`） | カメラを付けた子 entity | `CameraDistance`, `Height` |
| `camera_layer_bob_component`（抽象・直接は付けない） | 入ったプレイヤーの `camera_director_component` の層に `camera_bob_modifier` を積む。出たら `Cancel`。どの層かは派生で選ぶ | カメラを付けた子 entity | `Amplitude`, `Period` |
| └ `camera_pre_bob_component` / `camera_post_bob_component` / `camera_presentation_bob_component` | Pre / Post / Presentation の層に積む | 同上 | なし |
| `camera_fov_component` | 同じ entity の `perspective_camera_component.FieldOfView`（ラジアン）に、度で指定した画角を `DegreesToRadians` で入れる | カメラを付けた子 entity（`perspective_camera_component` と同じ） | `FovDegrees` |

イベント：`camera_target_event`（`Zone`：送り元のゾーン、`Agent`：出入りした人、`Target`：キャラクターの entity、`Entered`：入った / 出た）

モディファイアー：`camera_bob_modifier`（`camera_modifier` の派生。`Offset` のぶんだけ `RenderLocation` を上下にずらす）

## イベントの流れ

```
プレイヤーがゾーンに入る
  → volume_detector_component：SendUp(volume_entered_event)
  → camera_zone_component（OnReceive、Volume = Entity）：Director.AddCamera(子のカメラ, Priority)
  → SendDown(camera_target_event{Entered := true})
      → 子 entity の camera_*_follow_component：カメラの CameraModifiers に AddModifier
      → 子 entity の camera_*_bob_component：Target → player → director の、派生が決めた層に AddModifier
プレイヤーが出る
  → 足したカメラを Cancel → SendDown(camera_target_event{Entered := false})
      → follow：その人の分のモディファイアーを Cancel
      → bob：その人の分のモディファイアーを Cancel
```

`camera_fov_component` はイベントに関係なく、`OnBeginSimulation` で画角を入れるだけです。

## レベルでの置き場所

エリア中心 (8000, 8000)。どのゾーンも子にカメラの entity を 1 つ持っています。ゾーンの entity には `volume_detector_component` を付けます。

- `CameraFixedZone`：固定位置のカメラ
- `CameraTopDownZone`：見下ろしで追うカメラ
- `CameraOrthoZone`：平行投影（orthographic）のカメラ
- `CameraOrbitZone`：回り込めるカメラ

## 試してみよう

1. `CameraTopDownZone` の子のカメラから `camera_fixed_angle_follow_component` を外し、`camera_orbit_follow_component` を付ける。同じゾーンが回り込みカメラになります。
2. `camera_fixed_angle_follow_component` の `Pitch` を -80 にする。ほぼ真上からの見下ろしになります。
3. `CameraFixedZone` の子のカメラの entity を動かす / 回す。ゾーンに入ったときの画面がそのまま変わります（追従コンポーネントがなければ固定カメラ）。
4. 子のカメラコンポーネントを perspective から orthographic に付け替える。Verse はそのままで投影方法が変わります。
5. 子のカメラの entity に `camera_presentation_bob_component` を付け、`camera_post_bob_component` / `camera_pre_bob_component` に付け替えて見比べる。Presentation は見た目だけが揺れ、Post はブレンド後の結果が揺れ、Pre はカメラが評価される前の状態が揺れます（Pre の揺れは追従モディファイアーなどに上書きされて見えないことがあります）。`Amplitude` を 50、`Period` を 0.3 にすると違いが分かりやすくなります。
6. perspective のカメラの entity に `camera_fov_component` を付け、`FovDegrees` を 60 と 120 で比べる。`FieldOfView` はラジアンなので、度で書きたいときはこのコンポーネントを通します。

## UE5 との違い

- UE5 の `SetViewTargetWithBlend` で PlayerController のビューを切り替える代わりに、プレイヤーの `camera_director_component` にカメラを優先度つきで足し、`cancelable` で外します。
- SpringArm などのコンポーネント構成ではなく、「カメラモディファイアー」を積み重ねて追従の仕方を変えます。
- UE5 の CameraModifier（PlayerCameraManager に足す）に近いのが director の 3 層です。どの層に積むかで「ゲームプレイに影響する揺れ」と「見た目だけの揺れ」を分けられます。

## 注意

- `perspective_camera_component.FieldOfView` はラジアンです。度で考えたいときは `camera_fov_component` のように `DegreesToRadians` で直します。
- 揺れなどの効果は director の `PreCameraModifiers` / `PostCameraModifiers` / `PresentationCameraModifiers` に積みます。
