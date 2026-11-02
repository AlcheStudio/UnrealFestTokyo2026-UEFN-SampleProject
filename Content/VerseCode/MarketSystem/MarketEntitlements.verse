using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Marketplace }
using { VerseAsset.UI }

# エンタイトルメントの表示名（フィールドの既定値に使うので、引数なしの localizes にする）
CrownNameText<public><localizes>:message = "チュートリアルの王冠"
CrownDescriptionText<public><localizes>:message = "見た目だけの飾り。ゲームの有利不利には関わらない。"
CrownShortText<public><localizes>:message = "飾りの王冠"
CoinNameText<public><localizes>:message = "チュートリアルコイン"
CoinDescriptionText<public><localizes>:message = "クエストのごほうび。使うと減る。"
CoinShortText<public><localizes>:message = "コイン"

# 王冠：一度買えばずっと持っている（消費しない）エンタイトルメント
#   購入の仕組みで使うには <concrete> が必要
tutorial_crown_entitlement<public> := class<concrete>(entitlement):
    var Name<override>:message = CrownNameText
    var Description<override>:message = CrownDescriptionText
    var ShortDescription<override>:message = CrownShortText
    var Icon<override>:texture = T_IconCrown

# コイン：使うと減る（消費する）エンタイトルメント。最大 99 枚まで持てる
tutorial_coin_entitlement<public> := class<concrete>(entitlement):
    var Name<override>:message = CoinNameText
    var Description<override>:message = CoinDescriptionText
    var ShortDescription<override>:message = CoinShortText
    var Icon<override>:texture = T_IconCoin
    MaxCount<override>:int = 99
    Consumable<override>:logic = true

# 王冠を 100 V-Bucks で売るオファーを作る
MakeCrownOffer<public>():entitlement_offer =
    entitlement_offer:
        EntitlementType := tutorial_crown_entitlement
        Price := MakePriceVBucks(100.0)
        Name := CrownNameText
        Description := CrownDescriptionText
        ShortDescription := CrownShortText
        Icon := T_IconCrown
