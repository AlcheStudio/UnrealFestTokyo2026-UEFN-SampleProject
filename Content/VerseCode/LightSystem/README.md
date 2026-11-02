# LightSystem

公式のライトコンポーネントの色や明るさを Verse から変えるサンプルです。

## 見どころ

- **基底クラスで扱う**：`light_color_cycle_component` は基底の `light_component` の `ColorFilter` だけを使うので、球 / スポット / 矩形 / カプセルのどのライトに付けても動きます。
- **派生クラスの機能を使う**：`light_pulse_component` は `sphere_light_component` を名指しで取り、`Intensity`（カンデラ）や `AttenuationRadius`（cm）も変えます。
- **Verse の書き方**
  - `Sin` で `Period` 秒周期の 0〜1 の比率を作り、`Lerp`（明るさ）と UtilitySystem の `LerpColor`（色）で補間しています。
  - `AttenuationRadius` は option なので `option{Radius}` で入れます。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `light_color_cycle_component` | ライトの色を `FirstColor` → `SecondColor` → `ThirdColor` の順に `Interval` 秒ごとに切り替える（@editable の配列は使わず、色を 3 つ別々に持つ） | 任意の `light_component`（`sphere_light_component` / `spot_light_component` など）と同じ entity | `FirstColor`, `SecondColor`, `ThirdColor`, `Interval` |
| `light_pulse_component` | 色と明るさを `ColorA`↔`ColorB`、`MinIntensity`↔`MaxIntensity` で行き来させる | `sphere_light_component` と同じ entity | `ColorA`, `ColorB`, `MinIntensity`, `MaxIntensity`, `Radius`, `Period` |

## イベントの流れ

```
light_color_cycle_component：loop { First → Second → Third の色を順に ColorFilter に入れ、そのたびに Sleep(Interval) }
light_pulse_component：毎フレーム Ratio = 0.5 + 0.5 * Sin(…) → 色と Intensity を Lerp
```

## レベルでの置き場所

エリア中心 (-4000, 4000)（KeyframeSystem と同じエリア）。

- `LightSample`：`light_pulse_component` で明滅するライト
- `LightCycleSample`：`light_color_cycle_component` で色が切り替わるライト
- `VariantSphereColorCycle`：球のライトに色の切り替えを付けた例

## 試してみよう

1. `LightCycleSample` の `FirstColor` / `SecondColor` / `ThirdColor` を好きな色に変える。
2. `LightSample` の `Period` を 0.5 にして速く明滅させる。`MaxIntensity` を上げて明るさの差を大きくする。
3. `LightCycleSample` のライトをスポットライトに替える。`light_color_cycle_component` はそのまま動きます。
4. `light_pulse_component` をスポットライトの entity に付けてみる。`sphere_light_component` が無いので何も起きません（基底で取るか派生で取るかの違い）。

## UE5 との違い

- UE5 では `ULightComponent` を Blueprint や C++ から参照して `SetLightColor` などを呼びます。Scene Graph では同じ entity の `light_component` を `GetComponent` で取り、`ColorFilter` や `Intensity` に値を入れるだけです。
- 基底の `light_component` で扱えば種類を問わず動き、派生（`sphere_light_component` など）を名指しすれば、その種類だけが持つ値も変えられます。
