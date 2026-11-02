using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# 役割：点から点へ、まっすぐ一定の速さで動かす（毎フレーム TickEvents.PrePhysics で位置を書く。経過は GetSimulationElapsedTime の差）
# 置き方：エディターで entity に付ける
# 同じ entity：path_runner_component
path_linear_motion_component<public> := class(path_motion_component):

    # 速さ（cm / 秒）
    @editable_number(float):
        MinValue := option{1.0}
        MaxValue := option{5000.0}
        ToolTip := LinearMotionSpeedTip
        Categories := array{PathCategory}
    Speed<public>:float = 300.0

    Travel<override>(Body:entity, From:vector3, To:vector3)<suspends>:void =
        Duration := Distance(From, To) / Max(Speed, 1.0)
        StartTime := GetSimulationElapsedTime()

        loop:
            Ratio := Min((GetSimulationElapsedTime() - StartTime) / Max(Duration, 0.01), 1.0)
            Body.MovePathBody(From + (To - From) * Ratio)
            if (Ratio >= 1.0):
                break
            TickEvents.PrePhysics.Await()

# 役割：点から点へ、山なりに跳んで移る
# 置き方：エディターで entity に付ける
# 同じ entity：path_runner_component
path_hop_motion_component<public> := class(path_motion_component):

    # 跳ぶ高さ（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10000.0}
        ToolTip := HopMotionHopHeightTip
        Categories := array{PathCategory}
    HopHeight<public>:float = 250.0

    # 1 回の跳躍にかける秒数
    @editable_number(float):
        MinValue := option{0.1}
        MaxValue := option{60.0}
        ToolTip := HopMotionHopTimeTip
        Categories := array{PathCategory}
    HopTime<public>:float = 1.2

    Travel<override>(Body:entity, From:vector3, To:vector3)<suspends>:void =
        StartTime := GetSimulationElapsedTime()

        loop:
            Ratio := Min((GetSimulationElapsedTime() - StartTime) / Max(HopTime, 0.01), 1.0)
            Lift := HopHeight * Sin(PiFloat * Ratio)
            Body.MovePathBody(From + (To - From) * Ratio + vector3{Up := Lift})
            if (Ratio >= 1.0):
                break
            TickEvents.PrePhysics.Await()
