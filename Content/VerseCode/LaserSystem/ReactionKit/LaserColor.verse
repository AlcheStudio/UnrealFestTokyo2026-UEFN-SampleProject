using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }

# 役割：レーザーが「相手（entity）」を狙っているときは TargetColor、場所だけを狙っているときは SweepColor にする
# 置き方：エディターで entity に付ける
# 同じ entity：laser_eye_component
laser_color_reaction_component<public> := class(laser_reaction_component):

    # 相手を狙っているときの色（明るく光らせるには 1 より大きくする）
    @editable:
        ToolTip := ColorReactionTargetColorTip
        Categories := array{LaserCategory}
    TargetColor<public>:color = color{R := 8.0, G := 0.2, B := 0.2}

    # 場所だけを狙っているときの色
    @editable:
        ToolTip := ColorReactionSweepColorTip
        Categories := array{LaserCategory}
    SweepColor<public>:color = color{R := 0.2, G := 4.0, B := 1.0}

    OnLocked<override>(Aim:laser_aim):void =
        if (Eye := Entity.GetComponent[laser_eye_component], Laser := Eye.FindLaser[]):
            if (Aim.Target?):
                set Laser.Color = TargetColor
            else:
                set Laser.Color = SweepColor
