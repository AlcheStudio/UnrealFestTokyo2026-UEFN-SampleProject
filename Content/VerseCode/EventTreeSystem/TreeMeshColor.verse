using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { UtilitySystem }

# 役割：tree_node_state_event を受け取ったら、状態（成功 / 失敗 / 未到達）ごとに指定した色でキューブを塗る
# 置き方：エディターで entity に付ける
# 同じ entity：SM_TutorialCube、tree_node_component
tree_mesh_color_component<public> := class<final_super>(component):

    # 成功（イベントを通した）ときの色
    @editable:
        ToolTip := MeshColorSucceededColorTip
        Categories := array{EventTreeCategory}
    SucceededColor<public>:color = color{R := 0.1, G := 1.0, B := 0.2}

    # 失敗（イベントを止めた）ときの色
    @editable:
        ToolTip := MeshColorFailedColorTip
        Categories := array{EventTreeCategory}
    FailedColor<public>:color = color{R := 1.0, G := 0.1, B := 0.1}

    # 未到達（イベントが届いていない）ときの色
    @editable:
        ToolTip := MeshColorUnreachedColorTip
        Categories := array{EventTreeCategory}
    UnreachedColor<public>:color = color{R := 0.35, G := 0.35, B := 0.35}

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (StateEvent := tree_node_state_event[SceneEvent]):
            case (StateEvent.State):
                tree_node_state.Succeeded => Entity.PaintCube(SucceededColor)
                tree_node_state.Failed => Entity.PaintCube(FailedColor)
                tree_node_state.Unreached => Entity.PaintCube(UnreachedColor)
        false
