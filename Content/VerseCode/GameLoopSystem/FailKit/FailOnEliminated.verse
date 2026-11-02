using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }

# 役割：挑戦者が倒されたらゲームを失敗（撃破）にする
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下
fail_on_eliminated_component<public> := class(game_fail_component):

    AwaitFail<override>(Loop:game_loop_component)<suspends>:void =
        if (Agent := Loop.Challenger?, Character := Agent.GetFortCharacter[]):
            Character.EliminatedEvent().Await()
        else:
            # 挑戦者のキャラクターが取れないときは失敗しない
            Sleep(Inf)
