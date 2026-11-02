using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Verse.org/Colors }
using { VerseAsset.VFX }

# 役割：開始時に、子の点を Order の順に NS_TutorialPathLine（流れる点の線）でつなぐ。終わるときは線を消す
#       付け外しするだけで、パスの通り道を見せる / 見せないを切り替えられる
# 置き方：エディターで entity に付ける
# 同じ entity：path_runner_component
path_guide_line_component<public> := class<final_super>(component):

    # 線の色
    @editable:
        ToolTip := GuideLineColorTip
        Categories := array{PathCategory}
    Color<public>:color = color{R := 0.2, G := 2.0, B := 4.0}

    # つなぐ線をまとめて置く entity（消すときにこれごと消す）
    var Holder<private>:?entity = false

    OnSimulate<override>()<suspends>:void =
        if (Runner := Entity.GetComponent[path_runner_component], First := Runner.FindNextPoint[false]):
            Lines := entity{}
            Entity.AddEntities(array{Lines})
            set Holder = option{Lines}

            var Current:path_point_component = First
            loop:
                if (Next := Runner.FindNextPoint[option{Current.Order}]):
                    AddLine(Lines, Current.GetPosition(), Next.GetPosition())
                    set Current = Next
                else:
                    break

    OnEndSimulation<override>():void =
        if (Lines := Holder?):
            Lines.RemoveFromParent()
        set Holder = false

        (super:)OnEndSimulation()

    AddLine<private>(Parent:entity, From:vector3, To:vector3):void =
        Line := entity{}
        Fx := NS_TutorialPathLine{Entity := Line}
        set Fx.BeamEnd = To
        set Fx.Color = Color

        Line.AddComponents(array{Fx})
        Parent.AddEntities(array{Line})
        Line.SetGlobalTransform(transform{Translation := From, Rotation := IdentityRotation(), Scale := vector3{Forward := 1.0, Left := 1.0, Up := 1.0}})
