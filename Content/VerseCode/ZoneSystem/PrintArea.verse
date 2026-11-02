using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Fortnite.com/Characters }

# 役割：Print を出してよい範囲を決めるエリア。誰かがこのエリアにいる間だけ、エリア内の entity からの AreaPrint が出る
#       「誰かいるか」は同じ entity の volume_detector_component の InsideCount で見る。範囲の判定は entity の位置からの水平距離（Radius）
#       detector が無いエリアは「誰もいない」扱いになる（そのエリアの中の Print は出ない）
#       エリアが 1 つも置かれていなければ、AreaPrint は今まで通りすべて出る
# 置き方：エディターで各展示の中心あたりの entity に付ける（OverlapAll のメッシュで出入りを取る）
# 同じ entity：OverlapAll のメッシュ（SM_TutorialVolumeCube など）、volume_detector_component
print_area_component<public> := class<final_super>(component):

    # このエリアとみなす水平の半径（cm）
    @editable_number(float):
        MinValue := option{100.0}
        MaxValue := option{50000.0}
        ToolTip := PrintAreaRadiusTip
        Categories := array{ZoneCategory}
    Radius<public>:float = 2000.0

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("print_area")

    # 今このエリアに誰かいれば成功する
    IsOccupied<internal>()<decides><transacts>:void =
        Entity.GetComponent[volume_detector_component].InsideCount() > 0

    # Position がこのエリアの範囲内なら成功する（高さは見ない）
    Contains<internal>(Position:vector3)<decides><transacts>:void =
        Center := Entity.GetGlobalTransform().Translation
        Gap := vector3{Forward := Position.Forward - Center.Forward, Left := Position.Left - Center.Left, Up := 0.0}
        Gap.Length() <= Radius

# Source の entity が「誰かのいる print_area_component の範囲内」にあるときだけ Print する
# print_area_component が 1 つも無いときは、そのまま Print する
# エリアは呼ぶたびに世界から探す（Print は出来事のときだけ呼ぶ想定。毎フレーム呼ばない）
(Source:entity).AreaPrint<public>(Text:string):void =
    if (Source.ShouldAreaPrint[]):
        Print(Text)

# message 版（AI の発話など、すでに message になっている文字列向け）
(Source:entity).AreaPrint<public>(Text:message):void =
    if (Source.ShouldAreaPrint[]):
        Print(Text)

# Print してよいとき成功する：print_area_component が 1 つも無い、または Source が誰かのいるエリアの中にある
(Source:entity).ShouldAreaPrint<internal>()<decides><transacts>:void =
    if (Simulation := Source.GetSimulationEntity[]):
        Areas := for (Area : Simulation.FindDescendantComponents(print_area_component)):
            Area
        Areas.Length = 0 or Source.IsInActiveArea[Areas]

(Source:entity).IsInActiveArea<internal>(Areas:[]print_area_component)<decides><transacts>:void =
    Position := Source.GetGlobalTransform().Translation
    Active := for (Area : Areas, Area.IsOccupied[], Area.Contains[Position]):
        Area

    Active.Length > 0
