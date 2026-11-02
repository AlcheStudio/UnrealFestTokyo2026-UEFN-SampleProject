using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# 秒数を小数点以下 1 桁の文字にする（12.34 → "12.3"）
FormatGameSeconds<internal>(Seconds:float)<transacts>:string =
    Tenths := Round[Seconds * 10.0] or 0
    Whole := Quotient[Tenths, 10] or 0
    Fraction := Mod[Tenths, 10] or 0

    "{Whole}.{Fraction}"

# 役割：ループに記録された秒数を「○.○ 秒で倒した！」のように画面の真ん中へ ShowTime 秒出す
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下。記録する段階（defeat_npc_step_component）より後の Order
result_step_component<public> := class(game_step_component):

    # 秒数のあとに続ける文字
    @editable:
        ToolTip := ResultSuffixTip
        Categories := array{GameLoopStepCategory}
    Suffix<public>:string = " 秒で倒した！"

    # 出しておく秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := ResultShowTimeTip
        Categories := array{GameLoopStepCategory}
    ShowTime<public>:float = 4.0

    RunStep<override>(Loop:game_loop_component)<suspends>:void =
        Loop.ShowCenter("{FormatGameSeconds(Loop.ClearSeconds)}{Suffix}")
        Sleep(ShowTime)
        Loop.ShowCenter("")
