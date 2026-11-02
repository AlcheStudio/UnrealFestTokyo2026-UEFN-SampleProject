# InventorySystem

Scene Graph のアイテム（`item_component`）を置く・拾う・戻すサンプルです。何を置くかは派生コンポーネントの付け替えで決め、アイテムの動きは `ChangeInventoryEvent` で追いかけます。

## 見どころ

- **抽象の基底＋派生**：`item_spawner_component` は「置いて、拾われたら待って、また置く」だけを持ち、何を置くかは派生の `CreateItem` が決めます。キューブを置くか、アサルトライフルを置くかは付けるコンポーネントで選びます。
- **アイテムも entity**：`cube_item_spawner_component` は素の `entity{}` に `SM_TutorialCube` / `item_component` / `fort_item_pickup_interactable_component` を付けるだけで「拾えるアイテム」を作ります。
- **Verse の書き方**
  - `item_return_component` は「時間切れ」と「先に自分で落とされた」を `race` で競わせ、結果を `logic` で受け取ります。
  - `AddEntities` のような取り消せない処理は、失敗コンテキスト（`if` の条件）の外で呼んでいます。
  - `Changed.CurrentInventory?` のように option の中身の有無で「インベントリに入った / ワールドに戻った」を見分けます。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `item_spawner_component`（抽象・直接は付けない） | 台座の上にアイテムを `Drop` で置き、拾われたら `RespawnTime` 秒後にまた置く基底 | — | `RespawnTime`, `Height` |
| └ `cube_item_spawner_component` | 拾えるキューブをコードで組み立てて置く | 台座の entity | `Size`, `Color`（＋基底の分） |
| └ `assault_rifle_spawner_component` | アサルトライフル（レア）を置く | 台座の entity | 基底の分 |
| `item_return_component` | 拾われて `ReturnTime` 秒たつと元の場所へ戻す（ブーメラン） | アイテムの entity（`item_component` と同じ） | `ReturnTime` |
| `item_status_print_component` | 拾う / 落とす / 装備 / 解除を Print する（観察用） | アイテムの entity（`item_component` と同じ） | `Label` |
| `rarity_color_component` | `rarity_component` のレア度を順に切り替え、その色でキューブを塗る | `rarity_component` / `SM_TutorialCube` と同じ entity | `Interval`（0 で切り替えない） |

## イベントの流れ

```
item_spawner_component：CreateItem → Drop（できなければ台座の子に）
  → ChangeInventoryEvent で拾われるまで待つ → Sleep(RespawnTime) → また置く

item_return_component：インベントリに入る
  → race { Sleep(ReturnTime) / 自分で落とされる }
  → 時間切れなら Item.Drop[元の場所]
```

## レベルでの置き場所

エリア中心 (0, -4000)。

- `ItemSpawnerSample`：キューブのアイテムを置く台座
- `ItemAssaultSpawnerSample`：アサルトライフルを置く台座
- `RaritySample`：レア度の色が切り替わるキューブ
- `ItemReturnSample`：拾うと数秒後に元の場所へ戻るアイテム
- `VariantItemPrintOnly`：`item_status_print_component` で状態を Print するだけのアイテム

## 試してみよう

1. `ItemSpawnerSample` の `cube_item_spawner_component` を外して `assault_rifle_spawner_component` を付ける。同じ台座からライフルが出るようになります。
2. `cube_item_spawner_component` の `Color` / `Size`、`RespawnTime` を変える。
3. `ItemReturnSample` を拾い、`ReturnTime` 秒以内に自分で落とした場合と、持ち続けた場合を比べる。
4. `RaritySample` の `Interval` を 0 にして、`rarity_component` のレア度をエディターで選ぶ。その色で止まります。

## UE5 との違い

- UE5 ではアイテムを Actor（ピックアップ）とデータ（インベントリ内の構造体など）に分けて作ることが多いですが、ここではアイテムは 1 つの entity のまま、ワールドとインベントリのあいだを移動します。
