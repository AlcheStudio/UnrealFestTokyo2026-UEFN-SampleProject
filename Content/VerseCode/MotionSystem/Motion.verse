using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

# MotionSystem のコンポーネントは、毎フレーム（TickEvents.PrePhysics）今のローカルトランスフォームを読み、自分の担当だけを書き換える
# 角度は GetSimulationElapsedTime から決めるので、フレームレートが変わっても速さは変わらない
#   orbit_component：水平位置（Forward / Left）
#   bob_component：高さ（Up）
#   spin_component：向き（Rotation）
# 担当が重ならないので、同じ entity に重ねて付けると動きが合成される

# 役割：置いた位置を中心に、水平に円を描いて回る（親がいれば親に対する位置で回る）
# 置き方：エディターで entity に付ける（bob_component / spin_component と重ねられる）
orbit_component<public> := class<final_super>(component):

    # 回る半径（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10000.0}
        ToolTip := OrbitRadiusTip
        Categories := array{MotionCategory}
    Radius<public>:float = 300.0

    # 回る速さ（度 / 秒、マイナスで逆回り）
    @editable_number(float):
        MinValue := option{-720.0}
        MaxValue := option{720.0}
        ToolTip := OrbitSpeedTip
        Categories := array{MotionCategory}
    Speed<public>:float = 60.0

    # 開始角度（度）
    @editable_number(float):
        MinValue := option{-360.0}
        MaxValue := option{360.0}
        ToolTip := OrbitPhaseTip
        Categories := array{MotionCategory}
    Phase<public>:float = 0.0

    OnSimulate<override>()<suspends>:void =
        Center := Entity.GetLocalTransform().Translation

        loop:
            Angle := DegreesToRadians(Phase + Speed * GetSimulationElapsedTime())
            Current := Entity.GetLocalTransform()

            Entity.SetLocalTransform(transform:
                Translation := vector3:
                    Forward := Center.Forward + Radius * Cos(Angle)
                    Left := Center.Left + Radius * Sin(Angle)
                    Up := Current.Translation.Up
                Rotation := Current.Rotation
                Scale := Current.Scale
            )

            TickEvents.PrePhysics.Await()

# 役割：置いた高さを中心に上下にふわふわ揺れる
# 置き方：エディターで entity に付ける（orbit_component / spin_component と重ねられる）
bob_component<public> := class<final_super>(component):

    # 揺れる幅（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := BobHeightTip
        Categories := array{MotionCategory}
    Height<public>:float = 50.0

    # 1 往復の秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := BobPeriodTip
        Categories := array{MotionCategory}
    Period<public>:float = 2.0

    # 開始角度（度。並べたときにずらすと波になる）
    @editable_number(float):
        MinValue := option{-360.0}
        MaxValue := option{360.0}
        ToolTip := BobPhaseTip
        Categories := array{MotionCategory}
    Phase<public>:float = 0.0

    OnSimulate<override>()<suspends>:void =
        Base := Entity.GetLocalTransform().Translation.Up

        loop:
            Angle := DegreesToRadians(Phase + 360.0 * GetSimulationElapsedTime() / Max(Period, 0.1))
            Current := Entity.GetLocalTransform()

            Entity.SetLocalTransform(transform:
                Translation := vector3:
                    Forward := Current.Translation.Forward
                    Left := Current.Translation.Left
                    Up := Base + Height * Sin(Angle)
                Rotation := Current.Rotation
                Scale := Current.Scale
            )

            TickEvents.PrePhysics.Await()

# 役割：その場でヨー方向に回り続ける
# 置き方：エディターで entity に付ける（orbit_component / bob_component と重ねられる）
spin_component<public> := class<final_super>(component):

    # 回る速さ（度 / 秒、マイナスで逆回転）
    @editable_number(float):
        MinValue := option{-720.0}
        MaxValue := option{720.0}
        ToolTip := SpinSpeedTip
        Categories := array{MotionCategory}
    Speed<public>:float = 90.0

    OnSimulate<override>()<suspends>:void =
        loop:
            Current := Entity.GetLocalTransform()

            Entity.SetLocalTransform(transform:
                Translation := Current.Translation
                Rotation := MakeRotationFromYawPitchRollDegrees(Speed * GetSimulationElapsedTime(), 0.0, 0.0)
                Scale := Current.Scale
            )

            TickEvents.PrePhysics.Await()
