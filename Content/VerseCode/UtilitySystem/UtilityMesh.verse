using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/SpatialMath }
using { VerseAsset.Mesh }
using { VerseAsset.Material }

# メッシュを「当たり判定なし・重なり検知あり」のトリガーにする（ゾーン、パッド、入口に共通）
(Mesh:mesh_component).SetupAsTrigger<public>():void =
    set Mesh.Collidable = false
    set Mesh.Queryable = true

# 実行時に組み立てる entity 用に、色付きのキューブのメッシュを作る（当たり判定なし）
MakeCubeMesh<public>(Body:entity, CubeColor:color):SM_TutorialCube =
    Mesh := SM_TutorialCube{Entity := Body}
    set Mesh.Collidable = false
    Paint := M_TutorialCube{}
    set Paint.Color = CubeColor
    set Mesh.BodyMat = Paint

    Mesh

# entity の大きさを Size 倍にする（位置と向きはそのまま）
(Body:entity).SetUniformScale<public>(Size:float):void =
    Current := Body.GetLocalTransform()
    Body.SetLocalTransform(transform{Translation := Current.Translation, Rotation := Current.Rotation, Scale := vector3{Forward := Size, Left := Size, Up := Size}})

# From と To のあいだの色を Ratio（0 で From、1 で To）で混ぜる（R / G / B をそれぞれ Lerp する）
LerpColor<public>(From:color, To:color, Ratio:float):color =
    color{R := Lerp(From.R, To.R, Ratio), G := Lerp(From.G, To.G, Ratio), B := Lerp(From.B, To.B, Ratio)}

# entity のキューブ（通常の SM_TutorialCube か、ボリューム用の SM_TutorialVolumeCube）を指定した色で塗る
(Target:entity).PaintCube<public>(PaintColor:color):void =
    Body := M_TutorialCube{}
    set Body.Color = PaintColor

    if (Mesh := Target.GetComponent[SM_TutorialCube]):
        set Mesh.BodyMat = Body
    else if (Volume := Target.GetComponent[SM_TutorialVolumeCube]):
        set Volume.BodyMat = Body
