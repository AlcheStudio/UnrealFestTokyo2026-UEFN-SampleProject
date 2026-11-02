using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Fortnite.com/SceneGraphCameras }

# カメラの追い方の派生（FollowKit）。どれを付けるかで、同じカメラが「見下ろし」にも「回り込み」にもなる
# 置き方：エディターで camera_zone_component の子 entity（カメラを付けた entity）に 1 つ付ける

# 役割：入ったプレイヤーを、決まった角度と距離から見下ろして追う（fort_fixed_angle_camera_modifier）
# 置き方：エディターで camera_zone_component の子 entity（カメラを付けた entity）に付ける
# 同じ entity：camera_component
camera_fixed_angle_follow_component<public> := class(camera_follow_component):

    # プレイヤーからカメラまでの距離（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10000.0}
        ToolTip := FixedFollowDistanceTip
        Categories := array{CameraCategory}
    CameraDistance<public>:float = 1200.0

    # 見下ろす角度（度。マイナスで下を向く）
    @editable_number(float):
        MinValue := option{-90.0}
        MaxValue := option{90.0}
        ToolTip := FixedFollowPitchTip
        Categories := array{CameraCategory}
    Pitch<public>:float = -50.0

    MakeModifier<override>(Target:entity):camera_modifier =
        Modifier := fort_fixed_angle_camera_modifier{TargetEntity := Target}
        set Modifier.CameraDistanceCentimeters = CameraDistance
        set Modifier.RotationOffset = MakeRotationFromYawPitchRollDegrees(0.0, Pitch, 0.0)

        Modifier

# 役割：入ったプレイヤーのまわりを回り込めるカメラにする（fort_orbit_camera_modifier）
# 置き方：エディターで camera_zone_component の子 entity（カメラを付けた entity）に付ける
# 同じ entity：camera_component
camera_orbit_follow_component<public> := class(camera_follow_component):

    # プレイヤーからカメラまでの距離（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10000.0}
        ToolTip := OrbitFollowDistanceTip
        Categories := array{CameraCategory}
    CameraDistance<public>:float = 600.0

    # 回り込む中心の高さ（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10000.0}
        ToolTip := OrbitFollowHeightTip
        Categories := array{CameraCategory}
    Height<public>:float = 150.0

    MakeModifier<override>(Target:entity):camera_modifier =
        Modifier := fort_orbit_camera_modifier{TargetEntity := Target}
        set Modifier.CameraDistanceCentimeters = CameraDistance
        set Modifier.CameraHeightCentimeters = Height

        Modifier
