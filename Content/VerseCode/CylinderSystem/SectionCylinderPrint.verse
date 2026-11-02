using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { ZoneSystem }

# 役割：ボリュームの出入り（volume_entered_event / volume_exited_event）を受け取ったら Print する
#       同じ entity のボリュームだけでなく、子孫の entity のボリュームの知らせも受ける（親に置くと子のシリンダーをまとめて見られる）
#       どのボリュームの知らせかは Volume で分かるので、Label に「この entity」か「子孫の entity（名前）」かを添えて出す
# 置き方：エディターで entity に付ける
# 同じ entity か子孫の entity：volume_detector_component（と SM_TutorialCylinder、volume_cylinder_component）
# イベントは消費しない（false を返す）ので、親 entity にも届き続ける
section_cylinder_print_component<public> := class<final_super>(component):

    # Print の先頭に付ける名前（どのシリンダーか見分ける用）
    @editable:
        ToolTip := SectionPrintLabelTip
        Categories := array{CylinderCategory}
    Label<public>:string = "Cylinder"

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent]):
            Entity.AreaPrint("[{Label}] Entered（{DescribeVolume(Entered.Volume)}）")
        else if (Exited := volume_exited_event[SceneEvent]):
            Entity.AreaPrint("[{Label}] Exited（{DescribeVolume(Exited.Volume)}）")
        false

    # 知らせの送り元が自分の entity か、子孫の entity か
    DescribeVolume<private>(Volume:entity)<transacts>:string =
        if (Volume = Entity) then "この entity" else "子孫の entity"
