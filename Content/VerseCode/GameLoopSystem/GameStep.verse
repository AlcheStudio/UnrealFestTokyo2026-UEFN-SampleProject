using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# 役割：ゲームの 1 段階の基底。何をするかは派生（StepKit）の RunStep が決める
#       ループは Order の小さい順に段階を動かし、RunStep が戻ったら次の段階へ進む
#       段階を入れ替えるときは Verse を変えず、別の派生コンポーネントを付ける
# 置き方：直接は置かない（派生を置く）。1 entity に 1 つまで
# 親：game_loop_component の entity の直下。Order は段階どうしで重ねない
game_step_component<public> := class<abstract><final_super>(component):

    # 実行する順番（小さいほど先）
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{100}
        ToolTip := StepOrderTip
        Categories := array{GameLoopStepCategory}
    Order<public>:int = 0

    # この段階ですること。戻ったら次の段階へ進む
    RunStep<public>(Loop:game_loop_component)<suspends>:void
