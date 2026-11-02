using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Fortnite.com/Characters }
using { UtilitySystem }
using { ZoneSystem }

# 役割：Text を出して Delay 秒後、挑戦者を出口（この entity の子 entity の位置と向き）へ移す
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下。たいてい一番後の Order
# 子：出口の位置に置いた entity を 1 つ
exit_step_component<public> := class(game_step_component):

    # 移す前に出す文字
    @editable:
        ToolTip := ExitTextTip
        Categories := array{GameLoopStepCategory}
    Text<public>:string = "出口へ移動します"

    # 文字を出してから移すまでの秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := ExitDelayTip
        Categories := array{GameLoopStepCategory}
    Delay<public>:float = 1.5

    RunStep<override>(Loop:game_loop_component)<suspends>:void =
        Loop.ShowCenter(Text)
        Sleep(Delay)

        if:
            Agent := Loop.Challenger?
            Character := Agent.GetFortCharacter[]
            ExitPoint := FindExitPoint[]
        then:
            Exit := ExitPoint.GetGlobalTransform()
            # 出口の entity が床の上に置いてあっても足元が床に埋まらないように、少し上げる
            Target := Exit.Translation + vector3{Up := 100.0}
            Moved := Character.TryTeleport(Target, Exit.Rotation)
            if (not Moved?):
                Entity.AreaPrint("[exit_step] 出口へ移せなかった")

        Loop.ShowCenter("")

    FindExitPoint<private>()<decides><transacts>:entity =
        first:
            Child : Entity.GetEntities()
            Child
