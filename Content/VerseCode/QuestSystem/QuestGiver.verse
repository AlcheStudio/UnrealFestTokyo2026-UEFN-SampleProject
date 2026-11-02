using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Presentation }
using { /Verse.org/Assets }
using { /Verse.org/Progression }
using { /UnrealEngine.com/Progression }
using { /Fortnite.com/Progression }
using { /Fortnite.com/Characters }
using { VerseAsset.UI }
using { ZoneSystem }
using { MarketSystem }
using { UtilitySystem }

# このサンプルで使うクエスト（「○○を N 回して、ごほうびをもらう」）
tutorial_quest<public> := class(basic_quest, has_description, has_icon):

# 役割：入ったプレイヤーにクエストを渡す基底（1 人 1 つ、達成するまでは渡し直さない）
#       クエストは fort_quest_collection に参加させるので、Fortnite のクエスト画面に出る
#       何をすれば進むかは派生の TrackProgress が決め、達成するとコイン（tutorial_coin_entitlement）を 1 枚もらえる
#       出入りの検知は同じ entity の volume_detector_component に任せ、volume_entered_event を OnReceive で受け取る（派生は TrackProgress だけ書く）
# 置き方：直接は置かない（派生を置く）
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
quest_giver_component<public> := class<abstract><final_super>(component):

    # クエストの名前
    @editable:
        ToolTip := QuestGiverTitleTip
        Categories := array{QuestCategory}
    Title<public>:string = "チュートリアルクエスト"

    # クエストの説明
    @editable:
        ToolTip := QuestGiverDescriptionTip
        Categories := array{QuestCategory}
    Description<public>:string = ""

    # 達成に必要な回数
    @editable_number(int):
        MinValue := option{1}
        MaxValue := option{100}
        ToolTip := QuestGiverRequiredCountTip
        Categories := array{QuestCategory}
    RequiredCount<public>:int = 5

    Collection<private>:fort_quest_collection = fort_quest_collection{}
    var Active<private>:[player]logic = map{}
    # 終わるときに、進行中のクエストの待ちを止める合図
    StopSignal<private>:event() = event(){}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("quest_giver")

    OnEndSimulation<override>():void =
        StopSignal.Signal()
        (super:)OnEndSimulation()

    # クエスト一覧に出すアイコン（派生で差し替える）
    QuestIcon<protected>()<transacts>:texture = T_IconBooth

    # Player が何かするたびに Objective の進みを増やす（達成したらキャンセルされる）
    TrackProgress<protected>(Player:player, Character:fort_character, Objective:progress_objective)<suspends>:void

    # 自分の entity のボリュームに入った人にクエストを渡す（待つ処理なので spawn）。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity, not Active[Entered.Player]?):
            spawn{GiveQuest(Entered.Player, Entered.Character)}
        false

    GiveQuest<private>(Player:player, Character:fort_character)<suspends>:void =
        if (set Active[Player] = true) {}
        defer:
            if (set Active[Player] = false) {}

        Needed := 1.0 * RequiredCount
        Objective := progress_objective:
            RequiredProgress := Needed

        Reward := entitlement_quest_reward:
            Entitlement := tutorial_coin_entitlement
            Quantity := 1
            Name := CoinNameText
            Description := CoinDescriptionText
            ShortDescription := CoinShortText
            Icon := T_IconCoin

        QuestCollection := Collection
        Quest := tutorial_quest:
            Name := TextMessage(Title)
            Description := TextMessage(Description)
            ShortDescription := TextMessage(Title)
            Icon := QuestIcon()
            Objective := Objective
            Collection := QuestCollection
        Quest.SetRewards(array{Reward})

        Info := quest_participant_info{}
        Info.SetContribute(true)
        Info.SetObserve(true)
        Info.SetReceive(true)

        Joined := Quest.Join(agent_quest_participant{Agent := Player}, Info)
        if (not Joined.GetSuccess[]):
            Entity.AreaPrint("[quest_giver] クエストに参加できなかった")
            return
        if (not Quest.Activate().GetSuccess[]):
            Entity.AreaPrint("[quest_giver] クエストを開始できなかった")
            return

        Entity.AreaPrint("[quest_giver] クエスト開始：{Title}")
        Completed := race:
            block:
                TrackProgress(Player, Character, Objective)
                false
            block:
                Done := Quest.CompleteEvent.Await()
                true
            block:
                StopSignal.Await()
                false

        if (Completed?):
            Entity.AreaPrint("[quest_giver] クエスト達成：{Title}")
