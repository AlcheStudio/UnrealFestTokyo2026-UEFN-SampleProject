using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { ZoneSystem }

# プレイヤーが展示エリアに入った
# 向き：area_label_component がエリアの entity から SendUp。受け手：祖先の area_name_hud_component。消費しない
area_entered_event<public> := class(scene_event):
    # 入ったプレイヤー
    Player<public>:player
    # エリアの名前（右中央に出す文字）
    AreaName<public>:string
    # 送り元のエリアの entity
    Area<public>:entity

# プレイヤーが展示エリアから出た
# 向き：area_entered_event と同じ。消費しない
area_exited_event<public> := class(scene_event):
    Player<public>:player
    AreaName<public>:string
    Area<public>:entity

# 役割：エリアの床に名前を付け、同じ entity の volume_detector_component の出入りを
#       area_entered_event / area_exited_event に言い換えて親へ SendUp する
#       出入りそのものは調べない（検知は volume_detector_component に任せる）
# 置き方：エディターでエリアの床の entity に付け、AreaName にエリア名を入れる
# 同じ entity：SM_TutorialAreaFloor、volume_detector_component、area_floor_component
# 親：area_name_hud_component の entity（SendUp で届く）
area_label_component<public> := class<final_super>(component):

    # エリアの名前（右中央に出す文字）
    @editable:
        ToolTip := AreaLabelAreaNameTip
        Categories := array{LayoutCategory}
    AreaName<public>:string = "エリア"

    # エリアの簡単な紹介（案内役の NPC が、入った人に話す）
    @editable:
        ToolTip := AreaLabelSummaryTip
        Categories := array{LayoutCategory}
    Summary<public>:string = ""

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("area_label")

    # Player がこのエリアの中にいれば成功する（検知は同じ entity の volume_detector_component）
    Contains<public>(Player:player)<decides><transacts>:void =
        Entity.GetComponent[volume_detector_component].IsInside[Player]

    # 自分の entity のボリュームの出入りだけを、エリアの出入りに言い換える。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            Entity.SendUp(area_entered_event{Player := Entered.Player, AreaName := AreaName, Area := Entity})
        else if (Exited := volume_exited_event[SceneEvent], Exited.Volume = Entity):
            Entity.SendUp(area_exited_event{Player := Exited.Player, AreaName := AreaName, Area := Entity})
        false

# Player が今いるエリア（area_label_component）を世界から探す。どのエリアにもいなければ失敗
# （祖先でない entity、たとえば案内役の NPC が「相手がどのエリアにいるか」を知るために使う。出来事のときだけ呼び、毎フレーム呼ばない）
(Simulation:entity).FindAreaOf<public>(Player:player)<decides><transacts>:area_label_component =
    first:
        Area : Simulation.FindDescendantComponents(area_label_component)
        Area.Contains[Player]
        Area
