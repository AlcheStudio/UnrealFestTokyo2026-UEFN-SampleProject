using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Chat }
using { /Verse.org/AgentGroup }
using { /UnrealEngine.com/Conversations }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { UtilitySystem }
using { ZoneSystem }

# 役割：ペルソナ NPC の振る舞い。NPC 自身の中で動くので、自分の entity の persona_component を確実に読める
#       1. 自分を出した台座（persona_npc_component）を探す
#       2. 台座の entity にある性格・声・割り込みの component を persona_component に入れる
#       3. 音声チャンネルを作って自分を入れ、シミュレーションに登録する
#       4. 台座の TalkRadius に入ったプレイヤーをチャンネルに入れ、台座のフックに知らせる（離れたら外す）
#       5. 話した文章を台座のエリアに Print し、台座に persona_subtitle_component があれば近くの人に字幕を出す
#       「近づいた人とどう関わるか」は台座に付いた派生が決める。この振る舞いはどの派生でも同じ
#       NPC 側で動きを足したいときは、この振る舞いを派生させて OnTalking を override する（案内役の persona_guide_behavior）
# 置き方：ペルソナ NPC のキャラクター定義（Character Definition）の振る舞いに指定する
persona_npc_behavior<public> := class(npc_behavior):

    # 台座を探す間隔（秒）と回数。SpawnAt が戻る前にこの振る舞いが始まることがあるので、少し待つ
    FindPedestalInterval<private>:float = 0.1
    FindPedestalCount<private>:int = 50

    # 近づいた・離れたを調べる間隔（秒）。近さを知らせるイベントは無いので、距離で調べる
    WatchInterval<private>:float = 0.25

    var Nearby<private>:[player]logic = map{}
    var SaySubscriptions<private>:[]cancelable = array{}
    # 自分を出した台座の entity（NPC が話したことをそのエリアに Print するため）
    var PedestalEntity<private>:?entity = false

    OnBegin<override>()<suspends>:void =
        if:
            NpcEntity := GetEntity[]
            NpcAgent := GetAgent[]
            Persona := NpcEntity.GetComponent[persona_component]
            Simulation := NpcEntity.GetSimulationEntity[]
        then:
            MaybePedestal := FindPedestal(Simulation, NpcAgent)
            if (Pedestal := MaybePedestal?):
                Talk(Pedestal, NpcAgent, Persona, Simulation)
            else:
                Print("[persona_npc_behavior] 自分を出した台座（persona_npc_component）が見つからない")
        else:
            Print("[persona_npc_behavior] NPC に persona_component が無い（キャラクター定義に Persona モディファイアを付ける）")

    # 自分を出した台座を探す（台座は SpawnAt の戻りで自分を覚えるので、見つかるまで少し待つ）
    FindPedestal<private>(Simulation:entity, NpcAgent:agent)<suspends>:?persona_npc_component =
        var Remaining:int = FindPedestalCount

        loop:
            Found := for (Pedestal : Simulation.FindDescendantComponents(persona_npc_component), Pedestal.Owns[NpcAgent]):
                Pedestal
            if (Pedestal := Found[0]):
                return option{Pedestal}

            set Remaining -= 1
            if (Remaining <= 0):
                return false
            Sleep(FindPedestalInterval)

    # 台座の設定を persona に入れ、音声チャンネルを作り、NPC がいるあいだ近づいた人を見続ける
    Talk<private>(Pedestal:persona_npc_component, NpcAgent:agent, Persona:persona_component, Simulation:entity)<suspends>:void =
        set PedestalEntity = option{Pedestal.Entity}
        ApplyProfile(Pedestal.Entity, Persona)

        Group := agent_group(persona_npc_member_info){}
        Channel := voice_channel(persona_npc_member_info){Name := TextMessage("AI の NPC"), Group := Group}
        # NPC もチャンネルに入れる（同じチャンネルにいないと会話相手にできない）
        NpcJoined := Group.AddMember(NpcAgent, persona_npc_member_info{})
        Added := Simulation.AddChatChannel(Channel)
        set SaySubscriptions = array:
            Persona.CommitSayEvent.Subscribe(OnSaid)
            Persona.StopSayEvent.Subscribe(OnStoppedSaying)

        defer:
            Release(Pedestal, NpcAgent, Group, Channel, Simulation)

        Pedestal.NotifyNpcReady(NpcAgent, Persona, Channel)

        sync:
            loop:
                WatchPlayers(Pedestal, NpcAgent, Persona, Group, Channel)
                Sleep(WatchInterval)
            OnTalking(Pedestal, NpcAgent, Persona, Channel)

    # 派生用：会話の準備ができてから NPC が消えるまで、近づいた人の監視と並行して動かす処理（既定は何もしない）
    OnTalking<protected>(Pedestal:persona_npc_component, NpcAgent:agent, Persona:persona_component, Channel:voice_channel(persona_npc_member_info))<suspends>:void =
        Sleep(Inf)

    # 派生用：距離に関係なく「近くにいる」扱いにするプレイヤーなら成功（既定は誰もいない。ついていく相手などに使う）
    IsAlwaysNear<protected>(Player:player)<decides><transacts>:void =
        false?

    # 台座の entity に付いている性格・声・割り込みの component を persona に入れる
    ApplyProfile<private>(Owner:entity, Persona:persona_component):void =
        if (Personality := Owner.GetComponent[persona_personality_component]):
            Personality.ApplyTo(Persona)
        if (Voice := Owner.GetComponent[persona_voice_component]):
            Voice.ApplyTo(Persona)
        if (Interrupt := Owner.GetComponent[persona_interrupt_component]):
            Interrupt.ApplyTo(Persona)

    # TalkRadius に入った・出たプレイヤーを調べ、チャンネルの出入りと台座への知らせを行う
    WatchPlayers<private>(Pedestal:persona_npc_component, NpcAgent:agent, Persona:persona_component, Group:agent_group(persona_npc_member_info), Channel:voice_channel(persona_npc_member_info)):void =
        if (NpcCharacter := NpcAgent.GetFortCharacter[], Playspace := Pedestal.Entity.GetPlayspaceForEntity[]):
            NpcPosition := NpcCharacter.GetTransform().Translation

            for (Player : Playspace.GetPlayers()):
                InRadius := if (Character := Player.GetFortCharacter[], Distance(Character.GetTransform().Translation, NpcPosition) <= Pedestal.TalkRadius) then true else false
                IsNear := if (InRadius? or IsAlwaysNear[Player]) then true else false
                WasNear := if (Nearby[Player]?) then true else false

                if (IsNear?, not WasNear?):
                    if (set Nearby[Player] = true) {}
                    Joined := Group.AddMember(Player, persona_npc_member_info{})
                    Pedestal.NotifyPlayerNear(Player, Persona, Channel)
                else if (WasNear?, not IsNear?):
                    if (set Nearby[Player] = false) {}
                    Pedestal.NotifyPlayerAway(Player)
                    Left := Group.RemoveMember(Player)

    # 近くにいた人を外し、チャンネルを外す（NPC が消えるときに defer から呼ばれる）
    Release<private>(Pedestal:persona_npc_component, NpcAgent:agent, Group:agent_group(persona_npc_member_info), Channel:voice_channel(persona_npc_member_info), Simulation:entity):void =
        for (Subscription : SaySubscriptions):
            Subscription.Cancel()
        set SaySubscriptions = array{}
        HideSubtitles()

        for (Player -> Near : Nearby, Near?):
            Pedestal.NotifyPlayerAway(Player)
            Left := Group.RemoveMember(Player)
        set Nearby = map{}

        LeftNpc := Group.RemoveMember(NpcAgent)
        Removed := Simulation.RemoveChatChannel(Channel)

    # NPC が話し始めた：台座のエリアに Print し、台座に persona_subtitle_component があれば近くの人の画面に字幕を出す
    OnSaid<private>(Said:tuple(?agent, message)):void =
        if (Owner := PedestalEntity?):
            Owner.AreaPrint(Said(1))
            if (Subtitle := Owner.GetComponent[persona_subtitle_component]):
                for (Player -> Near : Nearby, Near?):
                    Subtitle.Show(Player, Said(1))

    # NPC が話し終えた（途中で止められたときも）：字幕を消す
    OnStoppedSaying<private>(Interrupted:logic):void =
        HideSubtitles()

    HideSubtitles<private>():void =
        if (Owner := PedestalEntity?, Subtitle := Owner.GetComponent[persona_subtitle_component]):
            for (Player -> Near : Nearby):
                Subtitle.Hide(Player)
