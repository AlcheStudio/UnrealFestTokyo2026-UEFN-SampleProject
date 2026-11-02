# EnableSystem

同じ entity にある「有効 / 無効を切り替えられるコンポーネント」を、種類を問わずまとめて点滅させるサンプルです。

## 見どころ

- **インターフェースで扱う**：`enableable[Component]` に成功したものだけを対象にします。メッシュでもライトでもインタラクトでも、`enableable` を持っていれば同じコードで切り替わります。
- **Verse の書き方**
  - `for (Component : Entity.GetComponents(), Target := enableable[Component])` — `for` の条件が失敗した要素は飛ばされます（失敗フィルター）。
  - `OnSimulate` がキャンセルされたとき（セッション終了やコンポーネントを外したとき）に `defer` で全部を有効に戻します。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `enable_blink_component` | 同じ entity の `enableable` なコンポーネントを `OnTime` 秒有効 / `OffTime` 秒無効で繰り返す | 点滅させたいもの（`mesh_component` / `light_component` / `interactable_component` など）と同じ entity | `OnTime`, `OffTime` |

## イベントの流れ

```
OnSimulate：loop { 全部 Enable → Sleep(OnTime) → 全部 Disable → Sleep(OffTime) }
キャンセル時：defer → 全部 Enable
```

## レベルでの置き場所

エリア中心 (0, 4000)（InteractSystem と同じエリア）。

- `BlinkSample`：メッシュを点滅させる例
- `VariantBlinkInteract`：インタラクトも一緒に点滅する例（無効のあいだは調べられない）

## 試してみよう

1. `OnTime` / `OffTime` を変える。0.1 にすると高速で点滅します。
2. `BlinkSample` にライト（`sphere_light_component` など）を足す。Verse を触らずにライトも一緒に点滅します。
3. `VariantBlinkInteract` で、消えているあいだにインタラクトしてみる。`interactable_component` も無効になっているので反応しません。
4. セッション中に `enable_blink_component` を外す。`defer` によって全部有効の状態に戻ります。

## UE5 との違い

- UE5 では `SetVisibility` / `SetActive` / `SetCollisionEnabled` などをコンポーネントの種類ごとに呼び分けますが、ここでは `enableable` インターフェース 1 つで同じように扱えます。
