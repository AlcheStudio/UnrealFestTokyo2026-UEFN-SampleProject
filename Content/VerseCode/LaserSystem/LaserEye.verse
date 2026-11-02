using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { VerseAsset.VFX }
using { ZoneSystem }

# 役割：同じ entity の狙い先（laser_target_component の派生）が狙う点を返すあいだ、そこへ NS_TutorialLaser のレーザーを伸ばす
#       狙い始めに laser_locked_event、止めたときに laser_released_event を SendDown で流す（反応は ReactionKit のコンポーネントが受け取る）
#       レーザーは実行時に子 entity を作って出し、止めるときはその entity ごと消す
#       狙い先の component は開始時に 1 回だけ取り、毎フレーム（TickEvents.PrePhysics）FindAim を聞く
# 置き方：エディターで「目」の entity に付ける
# 同じ entity：laser_target_component の派生（1 つ）、反応（ReactionKit、いくつでも）、目の見た目のメッシュ
# 知らせ：laser_locked_event / laser_released_event を SendDown
# 外から（ReactionKit）：FindLaser で今出ているレーザーの VFX
laser_eye_component<public> := class<final_super>(component):

    # レーザーの太さ（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{100.0}
        ToolTip := EyeWidthTip
        Categories := array{LaserCategory}
    Width<public>:float = 6.0

    var Beam<private>:?entity = false
    var BeamFx<private>:?NS_TutorialLaser = false
    # 今狙っている相手（場所だけを狙っているときは false）
    var LockedTarget<private>:?entity = false

    OnSimulate<override>()<suspends>:void =
        defer:
            Hide()

        if (Finder := Entity.GetComponent[laser_target_component]):
            loop:
                TickEvents.PrePhysics.Await()
                if (Aim := Finder.FindAim[]):
                    Show(Aim)
                else:
                    Hide()
        else:
            Entity.AreaPrint("[laser_eye] laser_target_component の派生が同じ entity に必要です")

    # 狙い始めならレーザーを作って知らせ、狙っている最中なら終わりの点だけ動かす
    Show<private>(Aim:laser_aim):void =
        if (Fx := BeamFx?):
            set Fx.BeamEnd = Aim.Point

            # 狙う相手が替わったら、反応に「止めた → 狙い始めた」を送り直す
            if (not IsSameTarget[LockedTarget, Aim.Target]):
                Entity.SendDown(laser_released_event{Eye := Self})
                set LockedTarget = Aim.Target
                Entity.SendDown(laser_locked_event{Eye := Self, Aim := Aim})
        else:
            BeamEntity := entity{}
            Fx := NS_TutorialLaser{Entity := BeamEntity}
            set Fx.BeamEnd = Aim.Point
            set Fx.Width = Width
            BeamEntity.AddComponents(array{Fx})
            Entity.AddEntities(array{BeamEntity})

            set Beam = option{BeamEntity}
            set BeamFx = option{Fx}
            set LockedTarget = Aim.Target

            Entity.SendDown(laser_locked_event{Eye := Self, Aim := Aim})

    # レーザーを出していれば消して知らせる
    Hide<private>():void =
        if (BeamEntity := Beam?):
            set Beam = false
            set BeamFx = false
            set LockedTarget = false

            Entity.SendDown(laser_released_event{Eye := Self})
            BeamEntity.RemoveFromParent()

    # 2 つの狙い先が同じなら成功する（どちらも相手なし、または同じ entity）
    IsSameTarget<private>(A:?entity, B:?entity)<decides><transacts>:void =
        if (Left := A?):
            Right := B?
            Left = Right
        else:
            not B?

    # 反応から呼ぶ：今出ているレーザーの VFX（出していなければ失敗）
    FindLaser<internal>()<decides><transacts>:NS_TutorialLaser =
        BeamFx?
