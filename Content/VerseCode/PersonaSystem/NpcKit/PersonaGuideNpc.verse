using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Chat }
using { /UnrealEngine.com/Conversations }
using { UtilitySystem }
using { ZoneSystem }

# 役割：会場の案内役の NPC。近づいたプレイヤーと声で会話し、会場の構成や Verse の基本を答える
#       性格の代わりに、PersonaGuideKnowledge（PersonaGuideKnowledge.verse。役柄と会場の事実）を出てきた NPC の persona_component に入れる
#       （persona_personality_component は付けなくてよい。付けると、こちらが後から上書きする）
# 置き方：エディターで広場の entity に付け、Spawner に NPC スポナーを入れる
persona_guide_npc_component<public> := class(persona_npc_component):

    OnNpcReady<override>(NewNpc:agent, NewPersona:persona_component, NewChannel:voice_channel(persona_npc_member_info)):void =
        Knowledge := TextMessage(PersonaGuideKnowledge())
        if (not NewPersona.SetPersonality[Knowledge]):
            Entity.AreaPrint("[persona_guide_npc] 案内役の指示を設定できなかった")

    OnPlayerNear<override>(Player:player, NearPersona:persona_component, NearChannel:voice_channel(persona_npc_member_info)):void =
        JoinConversation(Player, NearPersona, NearChannel)
        Entity.AreaPrint("[persona_guide_npc] 会場のことを聞いてみよう")

    OnPlayerAway<override>(Player:player):void =
        LeaveConversation(Player)
