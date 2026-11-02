using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }

# 役割：入口から game_join_event が届くと、その人を挑戦者にして、直下の段階（game_step_component の派生）を Order の順に動かす
#       挑戦者は 1 人ずつ。動いているあいだに入った人は無視する
#       始めに game_started_event、終わりに game_ended_event を子孫へ流す。画面の文字もここから子孫へ流す
#       段階どうしで受け渡す結果（クリアまでの秒数）はこの component が持つ
# 置き方：エディターで entity に付ける。ゲーム 1 つに 1 つ
# 子：入口（game_entrance_component）、画面（game_hud_component）、段階（game_step_component の派生）をそれぞれ別の entity で直下に
# 知らせ：game_started_event / game_ended_event / game_center_text_event / game_status_text_event を子孫へ SendDown
# 外から：Challenger / ClearSeconds は読むだけ。FindChallengerEntity で挑戦者のキャラクターの entity
game_loop_component<public> := class<final_super>(component):

    # 今の挑戦者（いなければ false）
    var<private> Challenger<public>:?agent = false

    # 直前の挑戦でクリアまでにかかった秒数
    var<private> ClearSeconds<public>:float = 0.0

    JoinEvent<private>:event(agent) = event(agent){}

    OnSimulate<override>()<suspends>:void =
        loop:
            Agent := JoinEvent.Await()
            RunGame(Agent)

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Joined := game_join_event[SceneEvent], not Challenger?):
            JoinEvent.Signal(Joined.Agent)
        false

    # 段階から呼ぶ：画面の真ん中に文字を出す（空で消す）
    ShowCenter<internal>(Text:string):void =
        Entity.SendDown(game_center_text_event{Loop := Self, Text := Text})

    # 段階から呼ぶ：画面の上に状態を出す（空で消す）
    ShowStatus<internal>(Text:string):void =
        Entity.SendDown(game_status_text_event{Loop := Self, Text := Text})

    # 段階から呼ぶ：クリアまでの秒数を記録する
    SetClearSeconds<internal>(Seconds:float):void =
        set ClearSeconds = Seconds

    # 挑戦者のキャラクターの entity（NPC が狙う相手）。挑戦者がいない・倒されているときは失敗する
    FindChallengerEntity<public>()<decides><transacts>:entity =
        Challenger?.GetFortCharacter[].GetEntity[]

    RunGame<private>(Agent:agent)<suspends>:void =
        set Challenger = option{Agent}
        set ClearSeconds = 0.0

        Entity.SendDown(game_started_event{Loop := Self, Agent := Agent})

        defer:
            ShowCenter("")
            ShowStatus("")
            Entity.SendDown(game_ended_event{Loop := Self, Agent := Agent})
            set Challenger = false

        # 挑戦者がゲームから抜けたら、何も出さずに終わる（次の人が挑戦できるように）
        race:
            RunGameBody()
            AwaitChallengerLeft(Agent)

    # 挑戦者がプレイスペースからいなくなるまで待つ
    AwaitChallengerLeft<private>(Agent:agent)<suspends>:void =
        if (Playspace := Entity.GetPlayspaceForEntity[]):
            loop:
                Removed := Playspace.PlayerRemovedEvent().Await()
                if (Removed = Agent):
                    break
        else:
            Sleep(Inf)

    RunGameBody<private>()<suspends>:void =
        # 失敗条件があれば、「段階を進める」と「失敗を待つ」を race で競わせる（負けた方は自動でキャンセルされる）
        if (Fail := FindFail[]):
            Failed := race:
                block:
                    RunSteps()
                    false
                block:
                    Fail.AwaitFail(Self)
                    true

            if (Failed?):
                ShowStatus("")
                ShowCenter(Fail.FailText)
                Sleep(Fail.ShowTime)
        else:
            RunSteps()

    # 直下の段階を Order の順に動かす
    RunSteps<private>()<suspends>:void =
        var Next:?game_step_component = FindNextStep(false)

        loop:
            if (Step := Next?):
                Step.RunStep(Self)
                set Next = FindNextStep(option{Step.Order})
            else:
                break

    # 直下の失敗条件（最初に見つかった 1 つ）
    FindFail<private>()<decides><transacts>:game_fail_component =
        first:
            Child : Entity.GetEntities()
            Child.GetComponent[game_fail_component]

    # 直下の段階のうち、After より大きい Order で一番小さいもの（After が false なら一番小さいもの）
    FindNextStep<private>(After:?int)<transacts>:?game_step_component =
        var Best:?game_step_component = false

        for (Child : Entity.GetEntities(), Step := Child.GetComponent[game_step_component]):
            if (Previous := After?, Step.Order <= Previous):
            else if (Current := Best?, Current.Order <= Step.Order):
            else:
                set Best = option{Step}

        Best
