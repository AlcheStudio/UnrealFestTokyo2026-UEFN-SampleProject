using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Conversations }
using { UtilitySystem }
using { ZoneSystem }

# AI の NPC（persona_component）の設定を、付け替えられる component に分けたもの
#   persona_component の設定はエディターからは触れないので、開始時に Verse から入れる
#   性格は文字列の @editable、声と割り込みの扱いは「どの派生 component を付けるか」で選ぶ
#   同じ entity に persona_component があれば開始時に自分で入れる
#   台座（persona_npc_component）の entity に付けた場合は、NPC の振る舞い（persona_npc_behavior）が ApplyTo で NPC 側の persona_component に入れる

# 役割：persona_component に性格（AI への指示）を入れる
# 置き方：エディターで entity に付ける
# 同じ entity：persona_component（公式）か persona_npc_component の派生
persona_personality_component<public> := class<final_super>(component):

    # NPC の性格（AI への指示）
    @editable:
        ToolTip := PersonaPersonalityTip
        Categories := array{PersonaCategory}
    Personality<public>:string = "あなたは UEFN の展示の案内役です。Verse と Scene Graph について、やさしく短く答えてください。"

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Persona := Entity.GetComponent[persona_component]):
            ApplyTo(Persona)

    # Persona に性格を入れる（NPC の振る舞いが、出てきた NPC の persona_component に対して呼ぶ）
    ApplyTo<internal>(Persona:persona_component):void =
        PersonalityText := TextMessage(Personality)
        if (not Persona.SetPersonality[PersonalityText]):
            Entity.AreaPrint("[persona_personality] 性格を設定できなかった")

# 役割：同じ entity の persona_component の声を決める（抽象・直接は付けない）
#       どの声にするかは、下の派生 component のどれを付けるかで選ぶ
# 置き方：エディターで派生を 1 つ entity に付ける
# 同じ entity：persona_component（公式）
persona_voice_component<public> := class<abstract><final_super>(component):

    # 使う声（派生で決める）
    MakeVoice<protected>()<transacts>:voice_model

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Persona := Entity.GetComponent[persona_component]):
            ApplyTo(Persona)

    # Persona に声を入れる
    ApplyTo<internal>(Persona:persona_component):void =
        Voice := MakeVoice()
        if (not Persona.SetVoice[Voice]):
            Entity.AreaPrint("[persona_voice] 声を設定できなかった")

# 役割：NPC が話している最中に話しかけられたときの扱いを決める（抽象・直接は付けない）
# 置き方：エディターで派生を 1 つ entity に付ける
# 同じ entity：persona_component（公式）
persona_interrupt_component<public> := class<abstract><final_super>(component):

    # 割り込みの扱い（派生で決める）
    GetRule<protected>()<transacts>:persona_interruption_rule

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Persona := Entity.GetComponent[persona_component]):
            ApplyTo(Persona)

    # Persona に割り込みの扱いを入れる
    ApplyTo<internal>(Persona:persona_component):void =
        set Persona.PromptInterruptionRule = GetRule()
