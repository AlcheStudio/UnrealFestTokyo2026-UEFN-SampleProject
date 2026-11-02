using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { VerseAsset.Mesh }
using { VerseAsset.Material }
using { ZoneSystem }

# 役割：シリンダーに誰かが入っているあいだ、シリンダーの色を EnterColor にする。全員出たら volume_cylinder_component の色に戻す
#       section_cylinder_print_component と同じイベントを受け取る別の反応（付け替えるだけで「入ったらどうなるか」が変わる）
#       自分の entity のボリュームの知らせ（Volume = Entity）だけに反応し、中の人数は同じ entity の volume_detector_component の InsideCount で見る
# 置き方：エディターで entity に付ける
# 同じ entity：SM_TutorialCylinder、volume_cylinder_component、volume_detector_component
section_cylinder_color_component<public> := class<final_super>(component):

    # 入っているあいだの色
    @editable:
        ToolTip := SectionColorEnterColorTip
        Categories := array{CylinderCategory}
    EnterColor<public>:color = color{R := 1.0, G := 0.3, B := 0.1}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("section_cylinder_color")

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            PaintEnter()
        else if (Exited := volume_exited_event[SceneEvent], Exited.Volume = Entity):
            if (Detector := Entity.GetComponent[volume_detector_component], Detector.InsideCount() = 0, Cylinder := Entity.GetComponent[volume_cylinder_component]):
                Cylinder.Paint()
        false

    # volume_cylinder_component の不透明度などはそのままで、色だけ EnterColor にする
    PaintEnter<private>():void =
        if (Mesh := Entity.GetComponent[SM_TutorialCylinder], Cylinder := Entity.GetComponent[volume_cylinder_component]):
            Body := M_TutorialCylinder{}
            set Body.Color = EnterColor
            set Body.Opacity = Cylinder.Opacity
            set Body.FadeHeight = Cylinder.FadeHeight
            set Body.Glow = Cylinder.Glow
            set Body.PulsePeriod = Cylinder.PulsePeriod

            set Mesh.BodyMat = Body
