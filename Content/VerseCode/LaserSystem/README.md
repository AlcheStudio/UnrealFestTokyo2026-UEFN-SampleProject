# LaserSystem

「目」の entity がレーザー（`NS_TutorialLaser`）を伸ばすサンプルです。どこを狙うか（TargetKit）と、狙ったときに何が起きるか（ReactionKit）を、それぞれコンポーネントの付け替えで決めます。

## 見どころ

- **2 つの軸で付け替える**
  - 狙い方：`laser_target_component` の派生を 1 つ（プレイヤー / 円を掃射 / 目印）
  - 反応：ReactionKit のコンポーネントをいくつでも（色を変える / ダメージを与える）
  - 目（`laser_eye_component`）はどちらの中身も知らず、「狙う点があればレーザーを出す」だけです。
- **scene_event の SendDown**：目は狙い始めに `laser_locked_event`、止めたときに `laser_released_event` を流します。狙う相手が替わったときは「止めた → 狙い始めた」を送り直します。反応側は `false` を返すので、並べた反応すべてに届きます。
- **目印は登録簿で知る**：`laser_marker_component` が entity に `laser_marker_tag` を付け、あわせてラウンドごとの登録簿（`weak_map(session, []entity)`）に自分を登録します。`laser_marker_target_component` は毎フレーム `GetLaserMarkers()` を読むだけで、世界全体を `FindDescendantEntitiesWithTag` で探しません（毎フレームの世界検索を避ける）。目と目印は参照でつながっていません。
- **毎フレームの待ち方**：目（`laser_eye_component`）は `TickEvents.PrePhysics.Await()` で 1 フレームずつ進み、狙い先の component は開始時に 1 回だけ取ります。
- **実行時に作って消す**：レーザーは子 entity を作って `NS_TutorialLaser` を付け、止めるときは entity ごと `RemoveFromParent` します。
- **Verse の書き方**
  - `FindAim` は `<decides>`。狙うものが無ければ失敗し、目はレーザーを消します。
  - 反応（ReactionKit）は抽象の基底 `laser_reaction_component` を継承し、`OnLocked` / `OnReleased` の 2 つを override するだけです。イベントの受け取りと型の判定は基底が受け持ちます。
  - `laser_damage_reaction_component` は `OnLocked`（待てない）から `event` に `Signal` し、`OnSimulate` 側で `race` を使って「止まるまでダメージを与え続ける」流れを作っています。
  - `laser_sweep_target_component` は経過時間から角度を出し、`Cos` / `Sin` で円上の点を求めます。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `laser_eye_component` | 狙う点がある間レーザーを伸ばし、`laser_locked_event` / `laser_released_event` を `SendDown` | 目の entity（同じ entity に狙い方 1 つ、反応いくつでも、目の見た目のメッシュ） | `Width` |
| `laser_target_component`（抽象・直接は付けない） | どこを狙うかを `FindAim` で決める基底 | — | — |
| └ `laser_player_target_component` | `Range` 以内の一番近いプレイヤーを狙う | `laser_eye_component` と同じ entity | `Range`, `AimHeight` |
| └ `laser_sweep_target_component` | 足元の円をなぞるように掃射する（相手なし） | 同上 | `Radius`, `Speed`, `Height` |
| └ `laser_marker_target_component` | `Range` 以内の一番近い目印を狙う | 同上 | `Range` |
| `laser_marker_component` | この entity を「狙われる目印」にする（`laser_marker_tag` を付け、登録簿に登録する） | 狙わせたい entity（実行時に付けてもよい） | なし |
| `laser_reaction_component`（抽象・直接は付けない） | `laser_locked_event` / `laser_released_event` を受けて派生の `OnLocked` / `OnReleased` を呼ぶ基底 | — | — |
| └ `laser_color_reaction_component` | 相手を狙っているときは `TargetColor`、場所だけなら `SweepColor` | `laser_eye_component` と同じ entity | `TargetColor`, `SweepColor` |
| └ `laser_damage_reaction_component` | キャラクターを狙っている間、`Interval` 秒ごとに `Amount` のダメージ | `laser_eye_component` と同じ entity | `Amount`, `Interval` |

データ：`laser_aim`（`Point`：レーザーの終点、`Target`：狙っている entity。場所だけなら false、`Character`：狙っている相手のキャラクター。プレイヤーを狙うときだけ）

## イベントの流れ

```
laser_eye_component（毎フレーム）
  → 同じ entity の laser_target_component.FindAim[]
      成功：初回 → レーザーの子 entity を作る → SendDown(laser_locked_event)
            以降 → 終点だけ動かす。相手が替わったら released → locked を送り直す
      失敗：レーザーを消す → SendDown(laser_released_event)

  laser_locked_event   → color：色を決める / damage：ダメージを始める
  laser_released_event → damage：ダメージをやめる
```

## レベルでの置き場所

エリア中心 (0, -8000)。

- `EyePlayer`：近づいたプレイヤーを狙い、ダメージを与える目
- `EyeSweep`：足元を円を描いて掃射し続ける目
- `EyeMarker`：PathSystem のエリアにあり、パスを動く `PathMarkedCube` の本体（目印付き）を追いかける目

## 試してみよう

1. `EyeSweep` の `laser_sweep_target_component` を外して `laser_player_target_component` を付ける。掃射していた目がプレイヤーを狙うようになり、レーザーの色も `TargetColor` に変わります。
2. `EyePlayer` の `laser_damage_reaction_component` を外す（付いていなければ足して違いを比べる）。狙われてもダメージを受けなくなります（色だけの反応）。
3. 好きな entity に `laser_marker_component` を付け、`EyeMarker` の近く（`Range` 以内）に置く。近い方を狙うようになります。
4. `laser_eye_component` の `Width`、`laser_sweep_target_component` の `Radius` / `Speed` を変える。

## UE5 との違い

- UE5 ではレーザーの当たり先を Line Trace で求めることが多いですが、ここでは「狙い先を決めるコンポーネント」を差し替える形にしています。
- 狙う相手は Actor の参照やクラスでの検索ではなく、Scene Graph のタグ（`laser_marker_tag`）で探します。
