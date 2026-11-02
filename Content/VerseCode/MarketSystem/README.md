# MarketSystem

エンタイトルメント（持ち物の権利）を使った売り買いのサンプルです。王冠を V-Bucks で買う画面を出すことと、コインを無料で渡す / 消費することを試せます。

> **注意**：購入（`BuyOffer`）や エンタイトルメントの API は実験的・プラットフォーム依存の機能です。V-Bucks の購入は**公開されたアイランドでのみ成立**します。編集中のセッションでは画面の流れだけを確かめてください。

## 見どころ

- **エンタイトルメントをクラスで定義**：`tutorial_crown_entitlement`（消費しない王冠）と `tutorial_coin_entitlement`（`Consumable`、最大 99 枚のコイン）。購入の仕組みで使うため `<concrete>` が付いています。
- **ZoneSystem の再利用**：パッドは継承をせず、同じ entity に置いた ZoneSystem の `volume_detector_component` が `SendUp` する `volume_entered_event` を `OnReceive` で受けるだけで作っています。
- **Verse の書き方**
  - `BuyOffer` / `GrantEntitlement` / `ConsumeEntitlement` は待つ処理なので、イベントのハンドラーから `spawn{}` で呼んでいます。
  - 表示名は引数なしの `<localizes>` の `message`（フィールドの既定値に使うため）。
  - `?Count := Count` は名前付き引数です。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `market_buy_component` | インタラクトした人に王冠（100 V-Bucks）の購入画面を出す | `basic_interactable_component` とメッシュがある entity | なし |
| `market_grant_pad_component` | 入った人にコインを `Count` 枚無料で渡す | OverlapAll のメッシュ・`volume_detector_component` と同じ entity | `Count` |
| `market_consume_pad_component` | 入った人のコインを `Count` 枚消費する。足りなければ失敗 | OverlapAll のメッシュ・`volume_detector_component` と同じ entity | `Count` |

定義（MarketEntitlements.verse）：`tutorial_crown_entitlement`、`tutorial_coin_entitlement`、`MakeCrownOffer`（王冠を 100 V-Bucks で売るオファー）

## イベントの流れ

```
MarketBuy をインタラクト → spawn{ BuyOffer(Player, MakeCrownOffer()) } → 結果を Print
MarketGrantPad に入る  → spawn{ GrantEntitlement(コイン, Count) } → 所持枚数を Print
MarketConsumePad に入る → spawn{ ConsumeEntitlement(コイン, Count) } → 所持枚数を Print / 足りない
```

## レベルでの置き場所

エリア中心 (-8000, 8000)。

- `MarketBuy`：王冠の購入画面を出すスタンド
- `MarketGrantPad`：コインをもらえるパッド
- `MarketConsumePad`：コインを使うパッド

## 試してみよう

1. `MarketGrantPad` に何度か入ってからログを見る。所持枚数が増えていきます。
2. `MarketConsumePad` の `Count` を 3 にして、足りるとき / 足りないときの Print を比べる。
3. `MarketBuy` をインタラクトして購入画面の流れを確かめる（編集中のセッションでは実際の購入は成立しません）。
4. QuestSystem のクエストを達成するともらえるコインも、同じ `tutorial_coin_entitlement` です。もらってから `MarketConsumePad` で使ってみる。

## UE5 との違い

- UE5 ではストア連携をプラットフォームの Online Subsystem などで実装しますが、ここでは Verse の `/UnrealEngine.com/Marketplace` のエンタイトルメントとオファーで表します。
