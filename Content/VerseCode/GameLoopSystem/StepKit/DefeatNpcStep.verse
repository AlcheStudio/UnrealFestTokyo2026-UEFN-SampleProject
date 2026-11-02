using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }

# 役割：「NPC を倒せ！」を出し、画面の上に残り人数を出しながら、TargetCount 体倒されるまで待つ
#       この段階を始めてから倒し終わるまでの秒数を、ループに記録する
#       倒された知らせは NPC の振る舞い（game_npc_behavior）から届く。振る舞いは game_defeat_target_tag でこの段階を探す
# 置き方：エディターで entity に付ける。レベルに 1 つ
# 親：game_loop_component の entity の直下
# 前提：NPC スポナーのキャラクター定義の振る舞いが game_npc_behavior
# 外から（NpcKit）：NotifyDefeated / FindTarget / FindTargetAgent（隣の Kit から呼ぶので public。<internal> は宣言した module とその下にしか見えない）
defeat_npc_step_component<public> := class(game_step_component):

    # クリアに必要な人数
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{100}
        ToolTip := DefeatNpcTargetCountTip
        Categories := array{GameLoopStepCategory}
    TargetCount<public>:int = 3

    # 始めに真ん中に出す文字
    @editable:
        ToolTip := DefeatNpcIntroTextTip
        Categories := array{GameLoopStepCategory}
    IntroText<public>:string = "NPCを倒せ！"

    # 始めの文字を出しておく秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := DefeatNpcIntroTimeTip
        Categories := array{GameLoopStepCategory}
    IntroTime<public>:float = 2.0

    var Defeated<private>:int = 0
    var Running<private>:?game_loop_component = false
    DefeatedEvent<private>:event() = event(){}

    var TagKey<private>:?tag_key = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        set TagKey = option{Entity.AddTag(game_defeat_target_tag{})}

    OnEndSimulation<override>():void =
        if (Key := TagKey?, Entity.RemoveTag[Key]) {}
        set TagKey = false

        (super:)OnEndSimulation()

    RunStep<override>(Loop:game_loop_component)<suspends>:void =
        set Defeated = 0
        set Running = option{Loop}
        defer:
            set Running = false
            Loop.ShowStatus("")

        StartTime := GetSimulationElapsedTime()
        Loop.ShowCenter(IntroText)
        ShowRemaining(Loop)

        branch:
            Sleep(IntroTime)
            Loop.ShowCenter("")
        loop:
            if (Defeated >= TargetCount):
                break
            DefeatedEvent.Await()
            ShowRemaining(Loop)

        Loop.SetClearSeconds(GetSimulationElapsedTime() - StartTime)

    # NPC（NpcKit の game_npc_behavior）から呼ぶ：1 体倒された（この段階が動いていないときは数えない）
    # <internal> は StepKit とその下にしか見えず、隣の NpcKit からは呼べないので public にしている
    NotifyDefeated<public>():void =
        if (Running?):
            set Defeated += 1
            DefeatedEvent.Signal()

    # NPC から呼ぶ：今狙うべき相手のキャラクターの entity（この段階が動いていなければ失敗）
    FindTarget<public>()<decides><transacts>:entity =
        Running?.FindChallengerEntity[]

    # NPC から呼ぶ：今狙うべき相手の agent（移動の目標に使う。この段階が動いていなければ失敗）
    FindTargetAgent<public>()<decides><transacts>:agent =
        Running?.Challenger?

    ShowRemaining<private>(Loop:game_loop_component):void =
        Remaining := Max(TargetCount - Defeated, 0)
        Loop.ShowStatus("残り {Remaining} 体")
