using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Chat }
using { /UnrealEngine.com/Conversations }
using { UtilitySystem }
using { ZoneSystem }

OracleEmptyText<localizes>:message = ""

# AI から受け取る答えの形（Prompt に型を渡すと、この形に合わせて返ってくる）
oracle_answer<public> := struct:
    Answer<public>:message = OracleEmptyText

# 役割：台座でインタラクトされるたびに、Question を NPC の AI に尋ねて答えを AreaPrint で出す（声は使わない）
#       NPC を出す部分は persona_npc_component に任せ、ここは「何を尋ねるか」だけを持つ
# 置き方：エディターで台座の entity に付け、Spawner に NPC スポナーを入れる
# 同じ entity：basic_interactable_component（公式）、インタラクトで狙えるメッシュ、persona_personality_component など（任意）
persona_oracle_component<public> := class(persona_npc_component):

    # AI への質問
    @editable:
        ToolTip := PersonaOracleQuestionTip
        Categories := array{PersonaCategory}
    Question<public>:string = "今日試すとよい Scene Graph の機能を 1 つ、一言でおすすめしてください。"

    var InteractSubscription<private>:?cancelable = false
    var Asking<private>:logic = false
    # 出てきた NPC の persona（OnNpcReady で受け取る）
    var OraclePersona<private>:?persona_component = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Interactable := Entity.GetComponent[interactable_component]):
            set InteractSubscription = option{Interactable.SucceededEvent.Subscribe(OnInteracted)}

    OnEndSimulation<override>():void =
        if (Previous := InteractSubscription?):
            Previous.Cancel()
        set InteractSubscription = false
        set OraclePersona = false

        (super:)OnEndSimulation()

    OnNpcReady<override>(NewNpc:agent, NewPersona:persona_component, NewChannel:voice_channel(persona_npc_member_info)):void =
        set OraclePersona = option{NewPersona}

    OnInteracted<private>(Agent:agent):void =
        if (not Asking?):
            spawn{Ask()}

    Ask<private>()<suspends>:void =
        set Asking = true
        defer:
            set Asking = false

        if (Persona := OraclePersona?):
            Session := Persona.GetAISession()
            Result := Session.Prompt(TextMessage(Question), oracle_answer)

            if (Reply := Result.GetSuccess[]):
                Entity.AreaPrint(Reply.Answer)
            else:
                Entity.AreaPrint("[persona_oracle] AI が答えられなかった")
        else:
            Entity.AreaPrint("[persona_oracle] NPC がまだ出ていない（スポナーと NPC 定義を確認）")
