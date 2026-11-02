using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Chat }
using { /UnrealEngine.com/Conversations }
using { /Fortnite.com/AI }
using { UtilitySystem }
using { LayoutSystem }

# 役割：会場の案内役 NPC の振る舞い。persona_npc_behavior の会話の仕組みに、「ついていく」と「エリアの紹介」を足す
#       ・話した人が「ついてきて」「案内して」と言うと AI が follow_player を選び、その人についていく。「止まって」「ここで待って」で止まる
#       ・ついていっている間、相手が別のエリア（area_label_component の床）に入るたび、そのエリアの Summary を元に短く紹介する
#       ・ついていっている相手は TalkRadius の外に出ても会話相手のまま（IsAlwaysNear）
#       ・紹介の内容は会話の履歴に残るので、そのまま質問に答えられる
# 置き方：案内役の NPC のキャラクター定義（Character Definition）の振る舞いに指定する。台座には persona_guide_npc_component
persona_guide_behavior<public> := class(persona_npc_behavior):

    # 「ついてきて」に応じるか（オフなら、ついていけないと答える）
    @editable:
        ToolTip := PersonaGuideCanFollowTip
        Categories := array{PersonaCategory}
    CanFollow<public>:logic = true

    # ついていくときに相手と保つ距離（cm）
    @editable_number(float):
        MinValue := option{100.0}
        MaxValue := option{2000.0}
        ToolTip := PersonaGuideFollowDistanceTip
        Categories := array{PersonaCategory}
    FollowDistance<public>:float = 300.0

    # 相手は動くので、この間隔（秒）で目的地と、いるエリアを見直す
    FollowRefreshSeconds<private>:float = 0.5

    # ついていっている相手（いなければ false）
    var Following<private>:?player = false
    # 最後に話しかけてきた人（「ついてきて」の相手）
    var LastSpeaker<private>:?agent = false
    # 相手が今いるエリアの名前（変わったら紹介する）
    var CurrentAreaName<private>:string = ""
    var Subscriptions<private>:[]cancelable = array{}
    # 話すのに使う persona と音声チャンネル（OnTalking で受け取る）
    var TalkPersona<private>:?persona_component = false
    var TalkChannel<private>:?voice_channel(persona_npc_member_info) = false

    OnTalking<override>(Pedestal:persona_npc_component, NpcAgent:agent, Persona:persona_component, Channel:voice_channel(persona_npc_member_info))<suspends>:void =
        set TalkPersona = option{Persona}
        set TalkChannel = option{Channel}
        Session := Persona.GetAISession()
        set Subscriptions = array:
            Persona.StartHearEvent.Subscribe(OnHear)
            Session.RegisterAction(MakePromptBinding("follow_player", "Use only when the speaker explicitly asks you to follow them, come along, show them around, or guide them."), false, npc_order, OnFollow)
            Session.RegisterAction(MakePromptBinding("stop_following", "Use only when the speaker explicitly tells you to stop following, wait here, or stay. Never use it on your own."), false, npc_order, OnStop)

        defer:
            for (Subscription : Subscriptions):
                Subscription.Cancel()
            set Subscriptions = array{}
            StopMoving()

        sync:
            FollowLoop()
            IntroduceLoop()

    # ついていっている間、相手のそばまで歩き続ける（NavigateTo は着くか失敗するまで戻らないので、戻ったら少し待って目的地を取り直す）
    FollowLoop<private>()<suspends>:void =
        loop:
            if (Player := Following?, Actions := FindActions[]):
                Moved := Actions.NavigateTo(MakeNavigationTarget(Player), ?MovementType := movement_type.Running, ?ReachRadius := FollowDistance)
            Sleep(FollowRefreshSeconds)

    # ついていっている間、相手が新しいエリアに入ったら紹介する
    IntroduceLoop<private>()<suspends>:void =
        loop:
            if (Player := Following?, Area := FindAreaOf[Player], Area.AreaName <> CurrentAreaName):
                set CurrentAreaName = Area.AreaName
                if (Area.Summary <> ""):
                    Say("The player you are guiding has just entered the area called \"{Area.AreaName}\". Using only the following notes, introduce in 2-3 sentences what can be seen here, and keep following them: {Area.Summary}")
            Sleep(FollowRefreshSeconds)

    # ついていっている相手は、距離に関係なく会話相手のまま（TalkRadius の外に出ても外さない）
    IsAlwaysNear<override>(Player:player)<decides><transacts>:void =
        Following? = Player

    # 話しかけてきた人を覚えておく（「ついてきて」「止まって」の相手）
    OnHear<private>(Speaker:agent):void =
        set LastSpeaker = option{Speaker}

    # AI が「ついていく」を選んだ。頼んだ人を覚え、今いるエリアを基準にする（入り直すまで紹介しない）
    OnFollow<private>(Order:npc_order):void =
        if (Speaker := LastSpeaker?, Player := player[Speaker]):
            if (CanFollow?):
                set Following = option{Player}
                set CurrentAreaName = if (Area := FindAreaOf[Player]) then Area.AreaName else ""
            else:
                Say("Briefly tell the speaker that you cannot follow them right now.")

    # AI が「止まる」を選んだ。ついていっている本人が言ったときだけ止まる（「ついてこないで」と言うまではついていく）
    OnStop<private>(Order:npc_order):void =
        if (Speaker := LastSpeaker?, Player := Following?, Speaker = Player):
            set Following = false
            StopMoving()

    # 指示を渡して AI に話させる。話している最中は割り込まず、その回は諦める（PromptToTalk が失敗する）
    Say<private>(Instructions:string):void =
        if (Persona := TalkPersona?, Channel := TalkChannel?):
            Text := TextMessage(Instructions)
            Spoken := logic{Persona.PromptToTalk[Text, Channel]}
            if (not Spoken?):
                Print("[persona_guide_behavior] 今は話せない（話している最中など）")

    StopMoving<private>():void =
        if (Actions := FindActions[]):
            Actions.StopNavigation()

    # 自分の entity の移動用 component
    FindActions<private>()<decides><transacts>:npc_actions_component =
        GetEntity[].GetComponent[npc_actions_component]

    # 相手が今いるエリア（どのエリアにもいなければ失敗）
    FindAreaOf<private>(Player:player)<decides><transacts>:area_label_component =
        GetEntity[].GetSimulationEntity[].FindAreaOf[Player]
