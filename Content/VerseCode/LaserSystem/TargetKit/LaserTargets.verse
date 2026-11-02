using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }

# 役割：Range 以内にいる一番近いプレイヤーを狙う（誰もいなければレーザーを消す）
# 置き方：エディターで entity に付ける
# 同じ entity：laser_eye_component
laser_player_target_component<public> := class(laser_target_component):

    # 狙い始める距離（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{20000.0}
        ToolTip := PlayerTargetRangeTip
        Categories := array{LaserCategory}
    Range<public>:float = 1500.0

    # キャラクターの足元から狙う高さ（cm）
    @editable_number(float):
        MinValue := option{-1000.0}
        MaxValue := option{1000.0}
        ToolTip := PlayerTargetAimHeightTip
        Categories := array{LaserCategory}
    AimHeight<public>:float = 100.0

    FindAim<override>()<decides><transacts>:laser_aim =
        Playspace := Entity.GetPlayspaceForEntity[]
        Origin := Entity.GetGlobalTransform().Translation

        var Best:?entity = false
        var BestCharacter:?fort_character = false
        var BestDistance:float = Range

        for:
            Player : Playspace.GetPlayers()
            Character := Player.GetFortCharacter[]
            Character.IsActive[]
            Body := Character.GetEntity[]
        do:
            Gap := Distance(Body.GetGlobalTransform().Translation, Origin)
            if (Gap < BestDistance):
                set BestDistance = Gap
                set Best = option{Body}
                set BestCharacter = option{Character}

        Target := Best?
        laser_aim{Point := Target.GetGlobalTransform().Translation + vector3{Up := AimHeight}, Target := option{Target}, Character := BestCharacter}

# 役割：足元の円をなぞるように、ずっとレーザーで掃射する（狙う相手はいない）
# 置き方：エディターで entity に付ける
# 同じ entity：laser_eye_component
laser_sweep_target_component<public> := class(laser_target_component):

    # 円の半径（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{20000.0}
        ToolTip := SweepTargetRadiusTip
        Categories := array{LaserCategory}
    Radius<public>:float = 600.0

    # 回る速さ（度 / 秒）
    @editable_number(float):
        MinValue := option{-720.0}
        MaxValue := option{720.0}
        ToolTip := SweepTargetSpeedTip
        Categories := array{LaserCategory}
    Speed<public>:float = 60.0

    # 目から見た円の高さ（cm。マイナスで下）
    @editable_number(float):
        MinValue := option{-10000.0}
        MaxValue := option{10000.0}
        ToolTip := SweepTargetHeightTip
        Categories := array{LaserCategory}
    Height<public>:float = -300.0

    FindAim<override>()<decides><transacts>:laser_aim =
        Origin := Entity.GetGlobalTransform().Translation
        Angle := DegreesToRadians(Speed * GetSimulationElapsedTime())

        laser_aim{Point := Origin + vector3{Forward := Radius * Cos(Angle), Left := Radius * Sin(Angle), Up := Height}}

# 役割：Range 以内にある一番近い目印（laser_marker_component を付けた entity）を狙う
#       目印は GetLaserMarkers（登録簿）から取る。毎フレーム世界をタグで探さない
# 置き方：エディターで entity に付ける
# 同じ entity：laser_eye_component
laser_marker_target_component<public> := class(laser_target_component):

    # 狙い始める距離（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{20000.0}
        ToolTip := MarkerTargetRangeTip
        Categories := array{LaserCategory}
    Range<public>:float = 2000.0

    FindAim<override>()<decides><transacts>:laser_aim =
        Origin := Entity.GetGlobalTransform().Translation

        var Best:?entity = false
        var BestDistance:float = Range

        for (Marker : GetLaserMarkers()):
            Gap := Distance(Marker.GetGlobalTransform().Translation, Origin)
            if (Gap < BestDistance):
                set BestDistance = Gap
                set Best = option{Marker}

        Target := Best?
        laser_aim{Point := Target.GetGlobalTransform().Translation + vector3{Up := 30.0}, Target := option{Target}}
