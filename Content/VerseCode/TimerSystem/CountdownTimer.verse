using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Fortnite.com/Characters }
using { UtilitySystem }
using { ZoneSystem }

# 役割：最初のプレイヤーが入ったら、timer（playable。実験的な API）で Seconds 秒のカウントダウンを始める
#       誰かが中にいるあいだは進み、全員出たら Pause、また誰かが入ったら Resume する
#       終わったら DoneColor に塗って Print し、2 秒後に待ち状態（IdleColor）へ戻る
#       出入りの検知は同じ entity の volume_detector_component に任せ、OnSimulate で取り出してその PlayerEnteredEvent / PlayerExitedEvent を待つ
#       「タイマーの終了」「出入りの見張り」「残り秒数の Print」を race で並べ、終了したら他の 2 つは自動でキャンセルされる
#       終わるときは timer を Stop する
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ（SM_TutorialVolumeCube）、volume_detector_component
countdown_timer_component<public> := class<final_super>(component):

    # カウントダウンの長さ（秒）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{600.0}
        ToolTip := CountdownTimerSecondsTip
        Categories := array{TimerCategory}
    Seconds<public>:float = 10.0

    # 進む速さ（1.0 で等速、2.0 で倍速）
    @editable_number(float):
        MinValue := option{0.1}
        MaxValue := option{10.0}
        ToolTip := CountdownTimerPlayRateTip
        Categories := array{TimerCategory}
    PlayRate<public>:float = 1.0

    # 待っているときの色
    @editable:
        ToolTip := CountdownTimerIdleColorTip
        Categories := array{TimerCategory}
    IdleColor<public>:color = color{R := 0.35, G := 0.35, B := 0.35}

    # カウントダウン中の色
    @editable:
        ToolTip := CountdownTimerRunningColorTip
        Categories := array{TimerCategory}
    RunningColor<public>:color = color{R := 1.0, G := 0.8, B := 0.1}

    # 終わったときの色
    @editable:
        ToolTip := CountdownTimerDoneColorTip
        Categories := array{TimerCategory}
    DoneColor<public>:color = color{R := 0.1, G := 1.0, B := 0.2}

    # 終わった色を見せる秒数
    ResultTime<private>:float = 2.0

    # 今動いているタイマー（OnEndSimulation で止めるために持つ）
    var Countdown<private>:?timer = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.PaintCube(IdleColor)

    OnEndSimulation<override>():void =
        if (Running := Countdown?):
            Running.Stop()
        set Countdown = false

        (super:)OnEndSimulation()

    OnSimulate<override>()<suspends>:void =
        if (Detector := Entity.GetComponent[volume_detector_component]):
            RunRounds(Detector)
        else:
            NoVolumeDetectorPrint("countdown_timer")

    # 入るのを待ってカウントダウンする、をくり返す
    RunRounds<private>(Detector:volume_detector_component)<suspends>:void =
        defer:
            Entity.PaintCube(IdleColor)

        loop:
            Entity.PaintCube(IdleColor)
            Detector.PlayerEnteredEvent.Await()
            Reason := RunCountdown(Detector)

            if (Reason = playable_stop_reason.Finished):
                Entity.PaintCube(DoneColor)
                Entity.AreaPrint("[countdown_timer] 終了")
                Sleep(ResultTime)
            else:
                Entity.AreaPrint("[countdown_timer] 途中で止めた")

    # タイマーを 1 本作って最後まで（または Stop されるまで）付き合い、止まった理由を返す
    RunCountdown<private>(Detector:volume_detector_component)<suspends>:playable_stop_reason =
        Running := timer{ReferenceClock := SecondsSinceEpochClock, StartSeconds := 0.0, EndSeconds := Seconds, PlayRate := PlayRate}
        set Countdown = option{Running}
        defer:
            set Countdown = false

        Entity.PaintCube(RunningColor)
        Running.Play()
        Entity.AreaPrint("[countdown_timer] 開始：{Seconds} 秒（{PlayRate} 倍速）")

        var Reason:playable_stop_reason = playable_stop_reason.Explicit
        race:
            block:
                set Reason = Running.StopEvent.Await()
            WatchOccupancy(Detector, Running)
            ReportRemaining(Running)

        Reason

    # 全員出たら Pause、誰かが入ったら Resume
    WatchOccupancy<private>(Detector:volume_detector_component, Running:timer)<suspends>:void =
        loop:
            race:
                block:
                    Detector.PlayerExitedEvent.Await()
                    if (Detector.InsideCount() = 0 and Running.IsPaused = false):
                        Running.Pause()
                        Entity.AreaPrint("[countdown_timer] 一時停止（残り {RemainingSeconds(Running)} 秒）")
                block:
                    Detector.PlayerEnteredEvent.Await()
                    if (Running.IsPaused?):
                        Running.Resume()
                        Entity.AreaPrint("[countdown_timer] 再開")

    # 1 秒ごとに残り秒数を Print する（一時停止中は出さない）
    ReportRemaining<private>(Running:timer)<suspends>:void =
        loop:
            Sleep(1.0)
            if (Running.IsPaused = false):
                Entity.AreaPrint("[countdown_timer] 残り {RemainingSeconds(Running)} 秒")

    # 残り秒数（timer は StartSeconds から EndSeconds へ進むので、終わりまでの差を取る）
    RemainingSeconds<private>(Running:timer):int =
        Remaining := Running.EndSeconds - Running.GetSeconds()

        if (Rounded := Ceil[Remaining]):
            Rounded
        else:
            0
