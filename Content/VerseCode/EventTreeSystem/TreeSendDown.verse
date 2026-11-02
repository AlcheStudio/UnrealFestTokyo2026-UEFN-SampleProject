using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# ツリーを上から下へ流れるイベント
# 向き：tree_send_down_component が根の entity から SendDown。受け手：子孫の tree_node_component。Pass が false のノードが消費して（true を返して）そこで止める
tree_event<public> := class(scene_event):
    # 送り元の根の entity
    Root<public>:entity

# 毎周期のはじめに全ノードを未到達に戻す
# 向き：tree_event と同じ。消費しない
tree_reset_event<public> := class(scene_event):
    Root<public>:entity

# 役割：Interval 秒ごとに、自分の entity から SendDown で tree_event を子孫へ流す
#       流す前に tree_reset_event で全ノードをグレーに戻す
# 置き方：エディターでツリーの根の entity に付ける
# 子：tree_node_component（どこまで届いたかを色で見せる）
tree_send_down_component<public> := class<final_super>(component):

    # イベントを流す周期（秒）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := SendDownIntervalTip
        Categories := array{EventTreeCategory}
    Interval<public>:float = 3.0

    # グレーに戻してから流すまでの間（秒）
    ResetDelay<private>:float = 0.5

    OnSimulate<override>()<suspends>:void =
        loop:
            Entity.SendDown(tree_reset_event{Root := Entity})
            Sleep(ResetDelay)
            Entity.SendDown(tree_event{Root := Entity})
            Sleep(Max(Interval - ResetDelay, 0.1))
