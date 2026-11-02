using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { UtilitySystem }

# 役割：tree_node_state_event を受け取ったら、状態（成功 / 失敗 / 未到達）ごとに指定した倍率へ大きさを変える
#       大きさは親から子へ伝わるので、子のノードも一緒に大きく / 小さくなる（親子付けの確認用）
#       tree_mesh_color_component と付け替える、または並べて使う
# 置き方：エディターで entity に付ける
# 同じ entity：tree_node_component
tree_scale_component<public> := class<final_super>(component):

    # 成功（イベントを通した）ときの倍率
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := ScaleSucceededScaleTip
        Categories := array{EventTreeCategory}
    SucceededScale<public>:float = 1.4

    # 失敗（イベントを止めた）ときの倍率
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := ScaleFailedScaleTip
        Categories := array{EventTreeCategory}
    FailedScale<public>:float = 0.6

    # 未到達（イベントが届いていない）ときの倍率
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := ScaleUnreachedScaleTip
        Categories := array{EventTreeCategory}
    UnreachedScale<public>:float = 1.0

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (StateEvent := tree_node_state_event[SceneEvent]):
            case (StateEvent.State):
                tree_node_state.Succeeded => Entity.SetUniformScale(SucceededScale)
                tree_node_state.Failed => Entity.SetUniformScale(FailedScale)
                tree_node_state.Unreached => Entity.SetUniformScale(UnreachedScale)
        false
