using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Verse.org/Colors }
using { VerseAsset.Mesh }
using { VerseAsset.Material }
using { UtilitySystem }
using { LaserSystem }

# 役割：本体を色の付いたキューブにする
# 置き方：エディターで entity に付ける
# 同じ entity：path_runner_component
path_cube_body_component<public> := class(path_body_component):

    # 大きさ（倍率。1 = 1 m）
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := CubeBodySizeTip
        Categories := array{PathCategory}
    Size<public>:float = 0.6

    # 色
    @editable:
        ToolTip := CubeBodyColorTip
        Categories := array{PathCategory}
    Color<public>:color = color{R := 1.0, G := 0.6, B := 0.1}

    BuildBody<override>(Body:entity):void =
        Body.AddComponents(array{MakeCubeMesh(Body, Color)})
        Body.SetUniformScale(Size)

# 役割：本体をホログラムの円柱にする
# 置き方：エディターで entity に付ける
# 同じ entity：path_runner_component
path_cylinder_body_component<public> := class(path_body_component):

    # 大きさ（倍率。1 = 半径 50 cm、高さ 1 m）
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := CylinderBodySizeTip
        Categories := array{PathCategory}
    Size<public>:float = 1.5

    # 色
    @editable:
        ToolTip := CylinderBodyColorTip
        Categories := array{PathCategory}
    Color<public>:color = color{R := 0.3, G := 1.0, B := 0.4}

    BuildBody<override>(Body:entity):void =
        Mesh := SM_TutorialCylinder{Entity := Body}
        set Mesh.Collidable = false
        Paint := M_TutorialCylinder{}
        set Paint.Color = Color
        set Mesh.BodyMat = Paint

        Body.AddComponents(array{Mesh})
        Body.SetUniformScale(Size)

# 役割：本体を「レーザーに狙われる目印」付きのキューブにする（laser_marker_target_component の目が追いかける）
# 置き方：エディターで entity に付ける
# 同じ entity：path_runner_component
path_marked_cube_body_component<public> := class(path_body_component):

    # 大きさ（倍率）
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := MarkedCubeBodySizeTip
        Categories := array{PathCategory}
    Size<public>:float = 0.6

    # 色
    @editable:
        ToolTip := MarkedCubeBodyColorTip
        Categories := array{PathCategory}
    Color<public>:color = color{R := 1.0, G := 0.2, B := 0.6}

    BuildBody<override>(Body:entity):void =
        Body.AddComponents(array{MakeCubeMesh(Body, Color), laser_marker_component{Entity := Body}})
        Body.SetUniformScale(Size)
