using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { ZoneSystem }

# 役割：プレイヤーが入ったら game_join_event を SendUp で親のループへ知らせる
#       出入りの検知は同じ entity の volume_detector_component に任せ、volume_entered_event を OnReceive で受け取る
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
game_entrance_component<public> := class<final_super>(component):

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("game_entrance")

    # 自分の entity のボリュームに入った人だけを知らせる。volume_entered_event 自体は消費しない（親のループにもそのまま届く）
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            Entity.SendUp(game_join_event{Entrance := Self, Agent := Entered.Player})
        false
