using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Marketplace }
using { /Fortnite.com/Characters }
using { ZoneSystem }

# 役割：同じ entity の interactable_component でインタラクトした人に、王冠の購入画面（BuyOffer）を出す
#       購入は公開されたアイランドでのみ成立する。編集中のセッションでは画面の流れだけ確かめる
# 置き方：エディターで entity に付ける
# 同じ entity：basic_interactable_component（公式）、インタラクトで狙えるメッシュ
market_buy_component<public> := class<final_super>(component):

    var Subscription<private>:?cancelable = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Interactable := Entity.GetComponent[interactable_component]):
            set Subscription = option{Interactable.SucceededEvent.Subscribe(OnInteracted)}

    OnEndSimulation<override>():void =
        if (Previous := Subscription?):
            Previous.Cancel()
        set Subscription = false

        (super:)OnEndSimulation()

    OnInteracted<private>(Agent:agent):void =
        if (Player := player[Agent]):
            spawn{Buy(Player)}

    Buy<private>(Player:player)<suspends>:void =
        Bought := BuyOffer(Player, MakeCrownOffer())

        if (Bought?):
            Entity.AreaPrint("[market_buy] 王冠を買った")
        else:
            Entity.AreaPrint("[market_buy] 購入しなかった")

# 役割：入ったプレイヤーにコインを Count 枚、無料で渡す（GrantEntitlement）
#       出入りの検知は同じ entity の volume_detector_component に任せ、volume_entered_event を OnReceive で受け取る
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
market_grant_pad_component<public> := class<final_super>(component):

    # 渡す枚数
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{100}
        ToolTip := MarketGrantPadCountTip
        Categories := array{MarketCategory}
    Count<public>:int = 1

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("market_grant_pad")

    # 自分の entity のボリュームに入った人に渡す（待つ処理なので spawn）。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            spawn{Grant(Entered.Player)}
        false

    Grant<private>(Player:player)<suspends>:void =
        Granted := GrantEntitlement(Player, tutorial_coin_entitlement, ?Count := Count)

        if (Granted?):
            PrintCoins(Entity, "[market_grant_pad] コインをもらった", Player)
        else:
            Entity.AreaPrint("[market_grant_pad] コインを渡せなかった")

# 役割：入ったプレイヤーのコインを Count 枚消費する（ConsumeEntitlement）。足りなければ失敗する
#       出入りの検知は同じ entity の volume_detector_component に任せ、volume_entered_event を OnReceive で受け取る
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
market_consume_pad_component<public> := class<final_super>(component):

    # 消費する枚数
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{100}
        ToolTip := MarketConsumePadCountTip
        Categories := array{MarketCategory}
    Count<public>:int = 1

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("market_consume_pad")

    # 自分の entity のボリュームに入った人から消費する（待つ処理なので spawn）。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            spawn{Consume(Entered.Player)}
        false

    Consume<private>(Player:player)<suspends>:void =
        Consumed := ConsumeEntitlement(Player, tutorial_coin_entitlement, ?Count := Count)

        if (Consumed?):
            PrintCoins(Entity, "[market_consume_pad] コインを使った", Player)
        else:
            Entity.AreaPrint("[market_consume_pad] コインが足りない")

# Player が今持っているコインの枚数を添えて Print する
PrintCoins<internal>(Source:entity, Text:string, Player:player)<suspends>:void =
    Purchased := GetPurchasedEntitlements(Player, tutorial_coin_entitlement)

    var Total:int = 0
    for (Owned : Purchased):
        set Total += Owned(1)

    Source.AreaPrint("{Text}（所持：{Total} 枚）")
