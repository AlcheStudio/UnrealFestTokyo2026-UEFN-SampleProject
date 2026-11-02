using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# 役割：画面の真ん中に Seconds から 1 まで 1 秒ずつ数え、最後に GoText を出して次へ進む
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下
countdown_step_component<public> := class(game_step_component):

    # 数え始める秒数
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{99}
        ToolTip := CountdownSecondsTip
        Categories := array{GameLoopStepCategory}
    Seconds<public>:int = 3

    # 数え終わったときに出す文字
    @editable:
        ToolTip := CountdownGoTextTip
        Categories := array{GameLoopStepCategory}
    GoText<public>:string = "GO!"

    RunStep<override>(Loop:game_loop_component)<suspends>:void =
        var Current:int = Seconds

        loop:
            if (Current <= 0):
                break
            Loop.ShowCenter("{Current}")
            Sleep(1.0)
            set Current -= 1

        Loop.ShowCenter(GoText)
        Sleep(1.0)
        Loop.ShowCenter("")
