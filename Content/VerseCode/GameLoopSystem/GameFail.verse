using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# 役割：ゲームの失敗条件の基底。何で失敗するかは派生（FailKit）の AwaitFail が決める
#       ループは「段階を順に動かす」と「失敗するまで待つ」を race で競わせ、失敗が先なら FailText を出して終わる
#       失敗条件を付けなければ、ゲームは失敗しない
# 置き方：直接は置かない（派生を置く）。ゲームに 1 つまで
# 親：game_loop_component の entity の直下
game_fail_component<public> := class<abstract><final_super>(component):

    # 失敗したときに真ん中に出す文字
    @editable:
        ToolTip := FailTextTip
        Categories := array{GameLoopCategory}
    FailText<public>:string = "失敗…"

    # 失敗の文字を出しておく秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := FailShowTimeTip
        Categories := array{GameLoopCategory}
    ShowTime<public>:float = 3.0

    # 失敗するまで待つ（失敗したら戻る）
    AwaitFail<public>(Loop:game_loop_component)<suspends>:void
