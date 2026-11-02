using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { VerseAsset.Mesh }
using { VerseAsset.Material }

# 役割：シリンダーの見た目（ホログラムの色・上へ消える不透明度・パルス周期）を設定する。見た目だけで、出入りは調べない
#       出入りは同じ entity の volume_detector_component が volume_entered_event / volume_exited_event として SendUp で知らせる
# 置き方：エディターで entity に付ける
# 同じ entity：SM_TutorialCylinder、volume_detector_component（出入りを知らせたいとき）
# 受け取り側：同じ entity か親 entity に付けた section_cylinder_* コンポーネント
volume_cylinder_component<public> := class<final_super>(component):

    # シリンダーの色
    @editable:
        ToolTip := VolumeCylinderColorTip
        Categories := array{CylinderCategory}
    Color<public>:color = color{R := 0.1, G := 0.7, B := 1.0}

    # 底の不透明度（上へ行くほど消えていく）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1.0}
        ToolTip := VolumeCylinderOpacityTip
        Categories := array{CylinderCategory}
    Opacity<public>:float = 0.9

    # 底から何割の高さで完全に消えるか（1.0 = 上面で消える）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{2.0}
        ToolTip := VolumeCylinderFadeHeightTip
        Categories := array{CylinderCategory}
    FadeHeight<public>:float = 1.0

    # 色の明るさ
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10.0}
        ToolTip := VolumeCylinderGlowTip
        Categories := array{CylinderCategory}
    Glow<public>:float = 1.5

    # パルスが下から上へ走る周期（秒）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := VolumeCylinderPulsePeriodTip
        Categories := array{CylinderCategory}
    PulsePeriod<public>:float = 2.0

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Paint()

    # 今の設定でマテリアルを塗り直す（section_cylinder_color_component が色を戻すときに呼ぶ）
    Paint<internal>():void =
        if (Mesh := Entity.GetComponent[SM_TutorialCylinder]):
            Body := M_TutorialCylinder{}
            set Body.Color = Color
            set Body.Opacity = Opacity
            set Body.FadeHeight = FadeHeight
            set Body.Glow = Glow
            set Body.PulsePeriod = PulsePeriod

            set Mesh.BodyMat = Body
