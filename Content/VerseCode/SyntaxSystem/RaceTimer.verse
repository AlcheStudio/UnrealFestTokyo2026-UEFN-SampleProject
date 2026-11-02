using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { UtilitySystem }
using { ZoneSystem }

# 役割：黄色に光っているあいだ（TimeLimit 秒）にキューブに入れたらグリーン、間に合わなければレッド
#       「入った」と「時間切れ」を race で競わせ、先に終わった方の結果（logic）を使う。負けた方は自動でキャンセルされる
#       出入りの検知は同じ entity の volume_detector_component に任せ、その PlayerEnteredEvent を待つ。終わるときは defer でグレーに戻す
# 置き方：エディターで entity に付ける
# 同じ entity：SM_TutorialVolumeCube（OverlapAll のボリューム用キューブ）、volume_detector_component
race_timer_component<public> := class<final_super>(component):

    # 入るまでの制限時間（秒）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := RaceTimerTimeLimitTip
        Categories := array{SyntaxCategory}
    TimeLimit<public>:float = 5.0

    # 結果を見せる秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := RaceTimerResultTimeTip
        Categories := array{SyntaxCategory}
    ResultTime<public>:float = 2.0

    OnSimulate<override>()<suspends>:void =
        if (Detector := Entity.GetComponent[volume_detector_component]):
            RunRounds(Detector)
        else:
            NoVolumeDetectorPrint("race_timer")

    # 「入った」と「時間切れ」の競争をくり返す
    RunRounds<private>(Detector:volume_detector_component)<suspends>:void =
        defer:
            Entity.PaintCube(SyntaxIdleColor)

        loop:
            Entity.PaintCube(SyntaxWaitColor)
            Reached := race:
                block:
                    Detector.PlayerEnteredEvent.Await()
                    true
                block:
                    Sleep(TimeLimit)
                    false

            if (Reached?):
                Entity.PaintCube(SyntaxSuccessColor)
                Entity.AreaPrint("[race_timer] 間に合った")
            else:
                Entity.PaintCube(SyntaxFailColor)
                Entity.AreaPrint("[race_timer] 時間切れ")

            Sleep(ResultTime)
