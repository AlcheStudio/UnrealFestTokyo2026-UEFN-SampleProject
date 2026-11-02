using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { UtilitySystem }
using { ZoneSystem }

# 役割：プレイヤーが入るたびに数を増やし、自前の event(int) を Signal する
#       入場は同じ entity の volume_detector_component が SendUp する volume_entered_event を OnReceive で受け取る
#       自分でも CountChangedEvent を Subscribe していて、届くたびにキューブを塗り直して Print する（Goal に達したら GoalColor）
#       自前の event も Subscribe できる（Await のループを書かなくてもコールバックで受けられる）
#       Subscribe が返す cancelable は持っておき、OnEndSimulation で Cancel する
#       外に出すのは MakeProxyListenable で包んだ listenable（Await / Subscribe はできるが、外から Signal はできない）
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ（SM_TutorialVolumeCube）、volume_detector_component
event_counter_component<public> := class<final_super>(component):

    # この回数に達したらキューブを GoalColor にする
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{100}
        ToolTip := EventCounterGoalTip
        Categories := array{EventCategory}
    Goal<public>:int = 5

    # Goal に達するまでの色
    @editable:
        ToolTip := EventCounterIdleColorTip
        Categories := array{EventCategory}
    IdleColor<public>:color = color{R := 0.2, G := 0.6, B := 1.0}

    # Goal に達したあとの色
    @editable:
        ToolTip := EventCounterGoalColorTip
        Categories := array{EventCategory}
    GoalColor<public>:color = color{R := 1.0, G := 0.8, B := 0.1}

    CountChangedEventInternal<private><final>:event(int) = event(int){}

    # 数が変わった（新しい数を渡す。外のコンポーネントも Subscribe / Await できる。Signal はこの component だけ）
    CountChangedEvent<public><final>:listenable(int) = MakeProxyListenable(CountChangedEventInternal)

    var Count<private>:int = 0
    var Subscription<private>:?cancelable = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        set Subscription = option{CountChangedEvent.Subscribe(OnCountChanged)}

        Entity.PaintCube(IdleColor)
        Entity.CheckVolumeDetector("event_counter")

    # 自分の entity のボリュームに入ったら数える。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            set Count += 1
            CountChangedEventInternal.Signal(Count)
        false

    OnEndSimulation<override>():void =
        if (Active := Subscription?):
            Active.Cancel()
        set Subscription = false

        (super:)OnEndSimulation()

    # Subscribe で受け取るコールバック（Signal と同じフレームで同期的に呼ばれる）
    OnCountChanged<private>(NewCount:int):void =
        if (NewCount >= Goal):
            Entity.PaintCube(GoalColor)
            Entity.AreaPrint("[event_counter] {NewCount} 回目（目標 {Goal} に到達）")
        else:
            Entity.PaintCube(IdleColor)
            Entity.AreaPrint("[event_counter] {NewCount} 回目（目標 {Goal}）")
