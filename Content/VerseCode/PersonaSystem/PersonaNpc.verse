using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Chat }
using { /Verse.org/AgentGroup }
using { /UnrealEngine.com/Conversations }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { UtilitySystem }
using { ZoneSystem }

# NPC との音声チャンネルの参加者ごとの設定（話せるか）
persona_npc_member_info<public> := class(has_voice_member_info):
    var CanBroadcast<override>:logic = true

# 役割：AI の NPC の「台座」。ラウンドが始まったら Spawner の SpawnAt で自分の位置に NPC を出し、どの NPC を出したかを覚える
#       NPC 側の処理（persona_component の取得、音声チャンネル、近づいた人の監視）は NPC の振る舞い persona_npc_behavior が持ち、
#       準備ができた・人が近づいた・離れたを、この台座のフック（OnNpcReady / OnPlayerNear / OnPlayerAway）に知らせてくる
#       会話するか、声で指示を受けるか、話すだけかは、どの派生を付けるかで決まる（抽象・直接は付けない）
#       同じ entity の persona_personality / persona_*_voice / 割り込みの component は、振る舞いが NPC の persona_component に入れる
# 置き方：エディターで派生を entity に付け、Spawner に NPC スポナーを入れる（entity の位置に NPC が出る）
#         スポナーの NPC 定義には Persona モディファイアと、振る舞い persona_npc_behavior を指定する
# 同じ entity：persona_personality_component、persona_voice_component の派生、persona_interrupt_component の派生（どれも任意）
persona_npc_component<public> := class<abstract><final_super>(component):

    # この NPC を出す NPC スポナー（自動スポーンは切っておく。SpawnAt でだけ出す）
    @editable:
        ToolTip := PersonaNpcSpawnerTip
        Categories := array{PersonaCategory}
    Spawner<public>:npc_spawner_device = npc_spawner_device{}

    # この距離（cm）まで近づいたプレイヤーを相手にする
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{20000.0}
        ToolTip := PersonaNpcTalkRadiusTip
        Categories := array{PersonaCategory}
    TalkRadius<public>:float = 500.0

    # 出した NPC
    var Npc<private>:?agent = false
    var RoundSubscription<private>:?cancelable = false

    # 派生用：NPC の準備ができたとき（persona と音声チャンネルがそろった）
    OnNpcReady<protected>(NewNpc:agent, NewPersona:persona_component, NewChannel:voice_channel(persona_npc_member_info)):void = {}

    # 派生用：プレイヤーが TalkRadius に入った / 出たとき（チャンネルへの出入りは振る舞い側で済んでいる）
    OnPlayerNear<protected>(Player:player, NearPersona:persona_component, NearChannel:voice_channel(persona_npc_member_info)):void = {}
    OnPlayerAway<protected>(Player:player):void = {}

    # 派生用：出した NPC（まだ出ていなければ失敗）
    FindNpc<protected>()<decides><transacts>:agent = Npc?

    # 派生用：プレイヤーをこの NPC の会話相手にする / やめる（声で話しかけられるようになる）
    JoinConversation<protected>(Player:player, NearPersona:persona_component, NearChannel:voice_channel(persona_npc_member_info)):void =
        Player.SetConversationTarget(NearPersona, NearChannel)

    LeaveConversation<protected>(Player:player):void =
        Player.ClearConversationTarget()

    # Spawner（デバイスへの参照）は OnBeginSimulation の時点では準備が終わっていないことがあるので、OnSimulate で購読を始める
    OnSimulate<override>()<suspends>:void =
        set RoundSubscription = Entity.SubscribeRounds(RunRound)

    OnEndSimulation<override>():void =
        if (Subscription := RoundSubscription?):
            Subscription.Cancel()
        set RoundSubscription = false
        set Npc = false

        (super:)OnEndSimulation()

    # ラウンドごとに NPC を出す。前のラウンドの NPC が生きていれば出し直さない
    RunRound<private>()<suspends>:void =
        if (Previous := Npc?, Previous.GetFortCharacter[].IsActive[]):
            return

        set Npc = false
        # SpawnAt はスポナーの上限（既定 1 体）に達していると出せない。前のラウンドで出した分を数え直してから出す
        Spawner.Reset()
        Spawned := Spawner.SpawnAt(Entity.GetGlobalTransform().Translation)

        if (NewNpc := Spawned?):
            set Npc = option{NewNpc}
        else:
            # 置き方の間違いは、ラウンド開始時に誰がどこにいても見えるように AreaPrint ではなく Print で出す
            Print("[persona_npc] NPC を出せなかった（Spawner の設定と、スポナーの NPC 定義・最大数を確認）")

    # 振る舞い用：この台座が出した NPC か
    Owns<internal>(Candidate:agent)<decides><transacts>:void =
        Npc? = Candidate

    # 振る舞い用：フックを呼ぶ入口（フック自体は派生が override する）
    NotifyNpcReady<internal>(NewNpc:agent, NewPersona:persona_component, NewChannel:voice_channel(persona_npc_member_info)):void =
        OnNpcReady(NewNpc, NewPersona, NewChannel)

    NotifyPlayerNear<internal>(Player:player, NearPersona:persona_component, NearChannel:voice_channel(persona_npc_member_info)):void =
        OnPlayerNear(Player, NearPersona, NearChannel)

    NotifyPlayerAway<internal>(Player:player):void =
        OnPlayerAway(Player)
