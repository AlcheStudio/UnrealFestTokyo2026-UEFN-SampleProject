using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# ノードが今どうなっているか
tree_node_state<public> := enum:
    # tree_event が届いていない
    Unreached
    # 届いて子へ通した
    Succeeded
    # 届いてここで止めた
    Failed

# ノードの状態が変わった
# 向き：tree_node_component が同じ entity の各 component へ SendDown（親や子の entity には届かない）。受け手：tree_mesh_color_component など。消費しない
tree_node_state_event<public> := class(scene_event):
    # 送り元のノード
    Node<public>:tree_node_component
    State<public>:tree_node_state

# 役割：tree_event を受け取って通すか止めるかを決め、結果（成功 / 失敗 / 未到達）を
#       tree_node_state_event で同じ entity のコンポーネントへ知らせる
#       見た目は持たない。どう見せるかは tree_mesh_color_component / tree_particle_component などを付け替えて決める
# 置き方：エディターで entity に付け、tree_send_down_component を付けた entity の子孫にする
tree_node_component<public> := class<final_super>(component):

    # true：イベントを子へ通す = 成功（OnReceive で false を返す）
    # false：イベントをここで止める = 失敗（OnReceive で true を返す = 消費）
    @editable:
        ToolTip := NodePassTip
        Categories := array{EventTreeCategory}
    Pass<public>:logic = true

    OnSimulate<override>()<suspends>:void =
        Notify(tree_node_state.Unreached)

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (tree_reset_event[SceneEvent]):
            Notify(tree_node_state.Unreached)
            return false

        if (tree_event[SceneEvent]):
            if (Pass?):
                Notify(tree_node_state.Succeeded)
                return false
            Notify(tree_node_state.Failed)
            return true

        false

    # 同じ entity のコンポーネントへだけ送る（親や子の entity には届かない）
    Notify<private>(State:tree_node_state):void =
        StateEvent := tree_node_state_event{Node := Self, State := State}

        for (Component : Entity.GetComponents()):
            Component.SendDown(StateEvent)
