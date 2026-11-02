# MotionSystem

「回る」「上下に揺れる」「その場で回転する」を別々のコンポーネントにして、重ねて付けると動きが合成されるサンプルです。

## 見どころ

- **担当を分けて合成する**：どのコンポーネントも毎フレーム今のローカルトランスフォームを読み、自分の担当だけを書き換えます。
  - `orbit_component`：水平位置（Forward / Left）
  - `bob_component`：高さ（Up）
  - `spin_component`：向き（Rotation）
  - 担当が重ならないので、同じ entity に 2 つ・3 つ付けると動きが足し合わされます。
- **親に対する動き**：ローカルトランスフォームを使うので、親がいれば親に対して動きます（BuildSystem の輪もこれを利用しています）。
- **Verse の書き方**：`GetSimulationElapsedTime()` から角度を計算して `TickEvents.PrePhysics.Await()`（1 フレーム待つ。component から使える）でループします。`transform:` のブロック書式で値を組み立てています。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `orbit_component` | 置いた位置を中心に水平に円を描いて回る | 動かしたい entity（`bob_component` / `spin_component` と重ねられる） | `Radius`, `Speed`（マイナスで逆回り）, `Phase` |
| `bob_component` | 置いた高さを中心に上下に揺れる | 同上 | `Height`, `Period`, `Phase` |
| `spin_component` | その場でヨー方向に回り続ける | 同上 | `Speed` |

## イベントの流れ

```
各コンポーネントの OnSimulate：loop {
  Current := GetLocalTransform()
  自分の担当（位置の Forward/Left・Up・Rotation のどれか）だけ書き換えて SetLocalTransform
  TickEvents.PrePhysics.Await()
}
```

## レベルでの置き場所

エリア中心 (-4000, 0)（BuildSystem と同じエリア）。

- `OrbitSample`：円を描いて回る
- `BobSpinSample`：上下に揺れながら回転する
- `MotionComboSample`：3 つを全部重ねた例

## 試してみよう

1. `OrbitSample` に `bob_component` を足す。円を描きながら上下する動きになります。
2. `MotionComboSample` から 1 つずつ外して、どの動きがどのコンポーネントの担当か確かめる。
3. `orbit_component` の `Speed` をマイナスにする / `Radius` を変える。
4. 同じ動きのものを並べて `bob_component` の `Phase` を少しずつずらす。波のように見えます。

## UE5 との違い

- UE5 では `RotatingMovementComponent` などを使うか、Tick で `SetActorLocation` を書きます。ここでは小さな動きのコンポーネントを重ねて組み合わせます。
