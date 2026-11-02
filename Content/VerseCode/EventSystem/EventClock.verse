using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { ZoneSystem }

# 役割：PlayerEnteredEvent を Await するループで入場を受け取り、今の時刻（エポック秒）と前回の入場からの経過秒を Print する
#       SecondsSinceEpochClock（clock）は 1970 年からの秒数を返す時計
#       event_counter_component の Subscribe（コールバック）に対して、こちらは Await（ループ）で受け取る書き方
#       入場は同じ entity の volume_detector_component の PlayerEnteredEvent を OnSimulate で待つ（継承せず、GetComponent で取って使う）
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ（SM_TutorialVolumeCube）、volume_detector_component
event_clock_component<public> := class<final_super>(component):

    # 前回の入場時刻（エポック秒）。まだ誰も入っていなければ false
    var LastEnteredSeconds<private>:?float = false

    OnSimulate<override>()<suspends>:void =
        if (Detector := Entity.GetComponent[volume_detector_component]):
            loop:
                Detector.PlayerEnteredEvent.Await()
                Now := SecondsSinceEpochClock.GetSeconds()

                if (Previous := LastEnteredSeconds?):
                    Entity.AreaPrint("[event_clock] 入場 エポック秒 {Now}（前回から {Now - Previous} 秒）")
                else:
                    Entity.AreaPrint("[event_clock] 入場 エポック秒 {Now}（最初の入場）")

                set LastEnteredSeconds = option{Now}
        else:
            NoVolumeDetectorPrint("event_clock")
