# BuildSystem

エディターで手作業で付けていた entity とコンポーネントを、Verse から実行時に組み立てるサンプルです。キューブの輪を作り、MotionSystem のコンポーネントで回します。

## 見どころ

- **コードで組み立てる**：`entity{}` で entity を作り、`SM_TutorialCube` / `orbit_component` / `bob_component` を `AddComponents` で付け、`AddEntities` で子に加えます。エディターでの操作と同じことを Verse で書いた形です。
- **後片付け**：`OnEndSimulation` で作った entity を `RemoveFromParent` で消します。
- **Verse の書き方**
  - `if` は式なので、`Extra:[]component = if (BobHeight > 0.0) then array{...} else array{}` のように条件で付けるコンポーネントの配列を切り替えています。
  - `for (Index := 1..Count)` で範囲をループし、開始角度の配列（`MakePhases`）を作っています。
- **ほかのシステムの再利用**：`using { MotionSystem }` で `orbit_component` / `bob_component` をそのまま使っています。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `build_ring_component` | 開始時に `Count` 個のキューブを子として作り、自分のまわりを回らせる。終了時に片付ける | 輪の中心にしたい entity | `Count`, `Radius`, `Speed`, `Size`, `BobHeight`（0 で `bob_component` を付けない）, `Color` |

## イベントの流れ

```
OnBeginSimulation → Build()
  → Count 回：entity{} → SM_TutorialCube + orbit_component (+ bob_component) を AddComponents
  → Entity.AddEntities（子にする）
OnEndSimulation → 作った子を RemoveFromParent
```

## レベルでの置き場所

エリア中心 (-4000, 0)（MotionSystem と同じエリア）。

- `BuildRingSample`：既定の設定の輪
- `VariantBuildRing`：@editable を変えた輪

## 試してみよう

1. `Count` を 3 や 12 に変える。キューブの数と間隔が変わります。
2. `BobHeight` を 0 にする。`bob_component` が付かなくなり、上下の揺れが止まります。
3. セッション中に `BuildRingSample` 自体を動かす。キューブは子なので、輪ごと付いてきます。
4. `Speed` をマイナスにする。逆回りになります。

## UE5 との違い

- UE5 では `SpawnActor` / `AddComponent` で Actor とコンポーネントを作りますが、ここでは素の `entity{}` にコンポーネントを足して「どんなものか」を組み立てます。クラスを継承して新しい Actor を作る必要はありません。
