# InfoSystem

各サンプルの横に立つ紹介の看板です。プレイヤーごとに専用のウィジェットの entity を作り、そのプレイヤーにだけ見せて、そのプレイヤーの方を向かせます。

## 見どころ

- **プレイヤーごとの表示**：`WBP_TutorialInfo_entity{}` をプレイヤーの人数ぶん子として作り、`SetPresentableToPlayers` で見せる相手を 1 人に絞ります。だれが見ても看板が自分の方を向きます。
- **実行時にコンポーネントを付ける**：子の看板に `tutorial_info_view_component` を `AddComponents` で付けます。エディターで置くのは `tutorial_info_component` だけです。
- **Verse の書き方**
  - 子にする前に `SetPresentableToPlayers` を呼び、1 フレームだけ全員に見えるのを防いでいます。
  - `race` で「毎フレーム向きを変える」と「そのプレイヤーが抜けるのを待つ」を競わせ、抜けたら看板ごと `RemoveFromParent` します。
  - `PlayerAddedEvent` を待って、後から入った人にも看板を作ります。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `tutorial_info_component` | 看板の置き場所と文字を持ち、プレイヤーごとに看板の子 entity を作る | 素の entity（ウィジェットの entity には付けない） | `Title`, `Body`, `Size` |
| `tutorial_info_view_component` | 子の看板を毎フレームそのプレイヤーの方へ水平に向ける。抜けたら消える | 実行時に `tutorial_info_component` が作る（エディターでは置かない） | なし（`Player` / `Size` は作るときに渡す） |

## イベントの流れ

```
tutorial_info_component（OnSimulate）
  → 今いるプレイヤー全員 + PlayerAddedEvent ごとに AddView
      → WBP_TutorialInfo_entity + tutorial_info_view_component を子に追加
tutorial_info_view_component
  → race { 毎フレーム Face() / PlayerRemovedEvent で本人が抜ける } → RemoveFromParent
```

## レベルでの置き場所

- 各サンプルの横に `Info<EntityName>` という看板（例：`InfoTutorialCylinder`、`InfoAbilityHealPad`）
- 各エリアに `AreaSign<Name>` の看板、広場に `AreaSignPlaza`

## 試してみよう

1. どれかの `Info*` の `Title` / `Body` を書き換えてセッションを始める。看板の文字が変わります。
2. `Size` を 3.0 や 10.0 に変える。
3. 看板のまわりを歩いてみる。縦には傾かず、水平にだけ自分の方を向き続けます。
4. 2 人以上で入ると、それぞれが自分の方を向いた看板を見ていることを確かめる。

## UE5 との違い

- UE5 では Widget Component を Actor に付けて「全員に同じ看板」を見せるのが基本ですが、ここでは看板をプレイヤーごとの entity にして、見せる相手を `SetPresentableToPlayers` で絞っています。
