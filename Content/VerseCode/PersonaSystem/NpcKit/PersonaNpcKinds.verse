using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Chat }
using { /UnrealEngine.com/Conversations }
using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { UtilitySystem }
using { ZoneSystem }

# 役割：近づいたプレイヤーと声で会話する NPC（入った人を会話相手にし、離れたら外す）
# 置き方：エディターで entity に付け、Spawner に NPC スポナーを入れる
persona_chat_npc_component<public> := class(persona_npc_component):

    OnPlayerNear<override>(Player:player, NearPersona:persona_component, NearChannel:voice_channel(persona_npc_member_info)):void =
        JoinConversation(Player, NearPersona, NearChannel)
        Entity.AreaPrint("[persona_chat_npc] 話しかけてみよう")

    OnPlayerAway<override>(Player:player):void =
        LeaveConversation(Player)

# 役割：会話に加えて、言葉の指示で動く NPC
#       会話の部分は persona_chat_npc_component と同じ（継承を重ねず、同じ 2 つの override を持つ）
#       ai_session.RegisterAction で「ついてくる」「止まる」「ここに来る」「ジャンプ」「踊る」を AI に教え、
#       話した人の言葉から AI が選んだ動きを実行する（移動は npc_actions_component、ジャンプと踊りは guard_actions_component）
# 置き方：エディターで entity に付け、Spawner に NPC スポナーを入れる
persona_command_npc_component<public> := class(persona_npc_component):

    var LastSpeaker<private>:?agent = false
    # 動いている最中の移動を止める合図
    StopSignal<private>:event() = event(){}
    var Subscriptions<private>:[]cancelable = array{}

    # 「ついてくる」で相手との距離をこれ以下に保つ（cm）。相手が動くので、この間隔（秒）で目的地を取り直す
    FollowDistance<private>:float = 250.0
    FollowRefreshSeconds<private>:float = 0.5
    # 「ここに来て」で相手のこの距離（cm）まで歩く
    ComeHereDistance<private>:float = 200.0

    OnNpcReady<override>(NewNpc:agent, NewPersona:persona_component, NewChannel:voice_channel(persona_npc_member_info)):void =
        Session := NewPersona.GetAISession()

        set Subscriptions = array:
            NewPersona.StartHearEvent.Subscribe(OnHear)
            Session.RegisterAction(MakePromptBinding("follow", "話している人に「ついてきて」「一緒に来て」と頼まれたときに使う"), false, npc_order, OnFollow)
            Session.RegisterAction(MakePromptBinding("stay", "「止まって」「そこで待って」と頼まれたときに使う"), false, npc_order, OnStay)
            Session.RegisterAction(MakePromptBinding("come_here", "「こっちに来て」と呼ばれたときに、話している人のところまで 1 回だけ歩く"), false, npc_order, OnComeHere)
            Session.RegisterAction(MakePromptBinding("jump", "「ジャンプして」と頼まれたときに使う"), false, npc_order, OnJump)
            Session.RegisterAction(MakePromptBinding("dance", "「踊って」「エモートして」と頼まれたときに使う"), false, npc_order, OnDance)

    OnEndSimulation<override>():void =
        for (Subscription : Subscriptions):
            Subscription.Cancel()
        set Subscriptions = array{}

        StopMoving()

        (super:)OnEndSimulation()

    OnPlayerNear<override>(Player:player, NearPersona:persona_component, NearChannel:voice_channel(persona_npc_member_info)):void =
        JoinConversation(Player, NearPersona, NearChannel)
        Entity.AreaPrint("[persona_command_npc] 話しかけてみよう（「ついてきて」「踊って」なども）")

    OnPlayerAway<override>(Player:player):void =
        LeaveConversation(Player)


    # 話しかけてきた人を覚えておく（「ついてきて」の相手）
    OnHear<private>(Speaker:agent):void =
        set LastSpeaker = option{Speaker}

    OnFollow<private>(Order:npc_order):void =
        StopMoving()
        if (Speaker := LastSpeaker?):
            spawn{FollowLoop(Speaker)}

    OnStay<private>(Order:npc_order):void =
        StopMoving()

    OnComeHere<private>(Order:npc_order):void =
        StopMoving()
        if (Speaker := LastSpeaker?):
            spawn{WalkTo(Speaker)}

    OnJump<private>(Order:npc_order):void =
        if (Actions := FindGuardActions[]):
            spawn{Actions.Jump()}

    OnDance<private>(Order:npc_order):void =
        StopMoving()
        if (Actions := FindGuardActions[]):
            spawn{Actions.PlayRandomEmote()}

    StopMoving<private>():void =
        StopSignal.Signal()
        if (Actions := FindActions[]):
            Actions.StopNavigation()

    FollowLoop<private>(Target:agent)<suspends>:void =
        if (Actions := FindActions[]):
            race:
                StopSignal.Await()
                loop:
                    Moved := Actions.NavigateTo(MakeNavigationTarget(Target), ?MovementType := movement_type.Running, ?ReachRadius := FollowDistance)
                    Sleep(FollowRefreshSeconds)

    WalkTo<private>(Target:agent)<suspends>:void =
        if (Actions := FindActions[]):
            race:
                StopSignal.Await()
                Moved := Actions.NavigateTo(MakeNavigationTarget(Target), ?ReachRadius := ComeHereDistance)

    # NPC 本体にある移動用の npc_actions_component（NPC がいなければ失敗）
    FindActions<private>()<decides><transacts>:npc_actions_component =
        FindNpc[].GetComponent[npc_actions_component]

    # NPC 本体にあるジャンプ・エモート用の guard_actions_component（ガードの種類でなければ失敗）
    FindGuardActions<private>()<decides><transacts>:guard_actions_component =
        FindNpc[].GetComponent[guard_actions_component]

# 役割：話すだけの NPC。近づいたプレイヤーに PromptToTalk で自分から声をかけるが、話しかけられても答えない
#       （会話相手にはしないので、声は聞こえるが質問はできない）
# 置き方：エディターで entity に付け、Spawner に NPC スポナーを入れる
persona_speaker_npc_component<public> := class(persona_npc_component):

    # 近づいたときに AI へ出す指示（何を話すか）
    @editable:
        ToolTip := PersonaSpeakerInstructionsTip
        Categories := array{PersonaCategory}
    Instructions<public>:string = "近くに来た人に短く挨拶して、近くにある展示を 1 つだけ紹介してください。"

    OnPlayerNear<override>(Player:player, NearPersona:persona_component, NearChannel:voice_channel(persona_npc_member_info)):void =
        Text := TextMessage(Instructions)
        if (not NearPersona.PromptToTalk[Text, NearChannel]):
            Entity.AreaPrint("[persona_speaker_npc] 今は話せない（話している最中など）")
