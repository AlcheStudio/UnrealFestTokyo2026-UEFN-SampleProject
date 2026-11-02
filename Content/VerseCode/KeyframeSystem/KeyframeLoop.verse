using { /Verse.org/SceneGraph }
using { /Verse.org/SceneGraph/KeyframedMovement }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# 役割：同じ entity の keyframed_movement_component に、Offset だけ動いて Spin 度回るキーフレームを設定する
#       PingPong が true なら行って戻る、false なら同じ動きを繰り返す（回転だけのとき向き）
# 置き方：エディターで entity に付ける
# 同じ entity：keyframed_movement_component（公式）
keyframe_loop_component<public> := class<final_super>(component):

    # 1 回の動きで移動する量（cm）
    @editable:
        ToolTip := KeyframeLoopOffsetTip
        Categories := array{KeyframeCategory}
    Offset<public>:vector3 = vector3{Up := 150.0}

    # 1 回の動きで回る角度（度、ヨー）
    @editable_number(float):
        MinValue := option{-360.0}
        MaxValue := option{360.0}
        ToolTip := KeyframeLoopSpinTip
        Categories := array{KeyframeCategory}
    Spin<public>:float = 0.0

    # 1 回の動きにかける秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := KeyframeLoopMoveTimeTip
        Categories := array{KeyframeCategory}
    MoveTime<public>:float = 2.0

    # true：行って戻る / false：同じ動きを繰り返す
    @editable:
        ToolTip := KeyframeLoopPingPongTip
        Categories := array{KeyframeCategory}
    PingPong<public>:logic = true

    # 開始と同時に動かすか（スイッチで動かすときは false）
    @editable:
        ToolTip := KeyframeLoopPlayOnStartTip
        Categories := array{KeyframeCategory}
    PlayOnStart<public>:logic = true

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()

        if (Movement := Entity.GetComponent[keyframed_movement_component]):
            Delta := keyframed_movement_delta:
                Transform := transform:
                    Translation := Offset
                    Rotation := MakeRotationFromYawPitchRollDegrees(Spin, 0.0, 0.0)
                    Scale := vector3{}
                Duration := MoveTime
                Easing := ease_in_out_cubic_bezier_easing_function{}

            if (PingPong?):
                Movement.SetKeyframes(array{Delta}, pingpong_keyframed_movement_playback_mode{})
            else:
                Movement.SetKeyframes(array{Delta}, loop_keyframed_movement_playback_mode{})

            if (PlayOnStart?):
                Movement.Play()

    OnEndSimulation<override>():void =
        if (Movement := Entity.GetComponent[keyframed_movement_component]):
            Movement.Stop()

        (super:)OnEndSimulation()
