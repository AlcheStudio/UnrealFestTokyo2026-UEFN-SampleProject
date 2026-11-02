# PathSystem

子 entity に置いた点（A 点・B 点 …）を順にたどって、本体が行っては戻るサンプルです。本体の見た目（BodyKit）と動き方（MotionKit）を、それぞれコンポーネントの付け替えで決めます。

## 見どころ

- **2 つの軸で付け替える**
  - 見た目：`path_body_component` の派生（キューブ / 円柱 / レーザーの目印付きキューブ）
  - 動き方：`path_motion_component` の派生（まっすぐ一定速度 / 山なりに跳ぶ）
  - `path_runner_component` はどちらの中身も知らず、「本体を作って、点から点へ運ばせる」だけです。
- **通り道は子 entity**：点はエディターで子 entity を置いて `path_point_component` を付けるだけ。順番は `Order` の小さい順で、点を足したり動かしたりすればパスが変わります（@editable の配列は使いません）。
- **実行時に作って消す**：本体は `entity{}` を作って `AddEntities` で子に加え、`defer` で `RemoveFromParent` します。ガイド線（`path_guide_line_component`）も同じく作って、終わるときに消します。
- **ほかのシステムとの連携**：`path_marked_cube_body_component` は本体に LaserSystem の `laser_marker_component` を付けるので、`EyeMarker` の目がパスを動く本体を追いかけます。
- **Verse の書き方**
  - 抽象メソッド `Travel` は `<suspends>`。着くまで戻らないので、ループ側は「動かす → 待つ → 次の点」と順に書けます。
  - `FindNextPoint` / `FindPreviousPoint` は `<decides>`。次の点が無いと失敗し、そこで向きを反転します。
  - 拡張メソッド `(Body:entity).MovePathBody` で、位置だけを書き換える処理をまとめています。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `path_runner_component` | 本体を作り、子の点を `Order` の順に行っては戻る（A → B → A …） | パスの親 entity（同じ entity に見た目・動き方を 1 つずつ） | `WaitTime` |
| `path_point_component` | 通り道の点。`HideInGame` ならゲーム中は目印のメッシュを隠す | `path_runner_component` の entity の直下（2 つ以上。`Order` は重ねない） | `Order`, `HideInGame` |
| `path_guide_line_component` | 点を `Order` の順に `NS_TutorialPathLine` の線でつなぐ | `path_runner_component` と同じ entity | `Color` |
| `path_body_component`（抽象・直接は付けない） | 本体の見た目を作る基底（`BuildBody`） | — | — |
| └ `path_cube_body_component` | 色付きのキューブ | `path_runner_component` と同じ entity | `Size`, `Color` |
| └ `path_cylinder_body_component` | ホログラムの円柱 | 同上 | `Size`, `Color` |
| └ `path_marked_cube_body_component` | レーザーの目印付きキューブ | 同上 | `Size`, `Color` |
| `path_motion_component`（抽象・直接は付けない） | 本体を点から点へ運ぶ基底（`Travel`） | — | — |
| └ `path_linear_motion_component` | まっすぐ一定の速さで動かす | `path_runner_component` と同じ entity | `Speed` |
| └ `path_hop_motion_component` | 山なりに跳んで移る | 同上 | `HopHeight`, `HopTime` |

## イベントの流れ

```
path_runner_component（OnSimulate）
  → 同じ entity の path_body_component.BuildBody(本体)  … 見た目を付ける
  → 本体を子に加えて最初の点へ
  → loop {
       次の点（Forward）か前の点（戻り）を探す
         見つかった → path_motion_component.Travel(本体, 今の点, 次の点) … 着くまで待つ
         無い       → 向きを反転
       Sleep(WaitTime)
     }
  → 終了時 defer：本体を RemoveFromParent

path_guide_line_component（OnSimulate）
  → 点を Order 順に NS_TutorialPathLine でつなぐ → 終了時に線をまとめて消す
```

## レベルでの置き場所

エリア中心 (8000, -8000)。

- `PathLinearCube`：キューブがまっすぐ動く
- `PathHopCylinder`：円柱が点から点へ跳ねる
- `PathMarkedCube`：目印付きのキューブ。同じエリアの `EyeMarker`（LaserSystem）がレーザーで追いかける

## 試してみよう

1. `PathLinearCube` の `path_linear_motion_component` を外して `path_hop_motion_component` を付ける。キューブが跳ねて移るようになります。
2. `PathHopCylinder` の `path_cylinder_body_component` を `path_cube_body_component` に替える。動きはそのまま、見た目だけ変わります。
3. どれかのパスの子の点を複製して `Order` を一番大きくし、別の場所に置く。通り道が 1 つ延びます。`path_guide_line_component` の線も付いてきます。
4. `path_point_component` の `HideInGame` を false にして、ゲーム中も点の目印を見えるようにする。`path_guide_line_component` を外すと線が消えます。
5. `PathMarkedCube` の本体を `path_cube_body_component` に替える。目印が無くなり、`EyeMarker` のレーザーが追わなくなります。

## UE5 との違い

- UE5 では Spline Component にポイントを打って `GetLocationAtDistanceAlongSpline` などでたどるのが定番ですが、ここでは点を子 entity として置き、順番は `Order` で決めています。
- 見た目と動き方を別々のコンポーネントにしているので、Blueprint の子クラスを作らずに組み合わせを変えられます。
