using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { VerseAsset.Mesh }
using { VerseAsset.Material }

# 役割：エリアの床（区切り）を指定した色で塗る。展示の見た目を整えるだけで、ゲームの動きには関わらない
#       床専用の M_TutorialAreaFloor（半透明の面・光る縁・マス目）を使う
# 置き方：エディターで entity に付ける
# 同じ entity：SM_TutorialAreaFloor（OverlapAll なので歩いても邪魔にならない）
area_floor_component<public> := class<final_super>(component):

    # 床の色
    @editable:
        ToolTip := AreaFloorFloorColorTip
        Categories := array{LayoutCategory}
    FloorColor<public>:color = color{R := 0.2, G := 0.6, B := 1.0}

    # 面の光り方
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10.0}
        ToolTip := AreaFloorGlowTip
        Categories := array{LayoutCategory}
    Glow<public>:float = 0.5

    # 面の透け具合（0 で透明、1 で不透明）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1.0}
        ToolTip := AreaFloorOpacityTip
        Categories := array{LayoutCategory}
    Opacity<public>:float = 0.35

    # マス目の数（一辺あたり）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{100.0}
        ToolTip := AreaFloorGridCountTip
        Categories := array{LayoutCategory}
    GridCount<public>:float = 8.0

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()

        if (Mesh := Entity.GetComponent[SM_TutorialAreaFloor]):
            Paint := M_TutorialAreaFloor{}
            set Paint.Color = FloorColor
            set Paint.Glow = Glow
            set Paint.Opacity = Opacity
            set Paint.GridCount = GridCount

            set Mesh.BodyMat = Paint
