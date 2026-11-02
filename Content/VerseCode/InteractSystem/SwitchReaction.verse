using { /Verse.org/SceneGraph }
using { /Verse.org/SceneGraph/KeyframedMovement }
using { /Verse.org/Simulation }

# 役割：switch_changed_event を受け取ったら、同じ entity のライト（light_component）を点けたり消したりする
# 置き方：エディターで entity に付け、interact_switch_component を付けた entity の子孫にする
# 同じ entity：sphere_light_component などの light_component（公式）
switch_light_component<public> := class<final_super>(component):

    # true にすると逆になる（スイッチ ON で消えて OFF で点く）
    @editable:
        ToolTip := SwitchLightInvertTip
        Categories := array{InteractCategory}
    Invert<public>:logic = false

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Changed := switch_changed_event[SceneEvent], Light := Entity.GetComponent[light_component]):
            if (Changed.On <> Invert):
                Light.Enable()
            else:
                Light.Disable()
        false

# 役割：switch_changed_event を受け取ったら、同じ entity の「有効 / 無効を切り替えられるコンポーネント」を全部まとめて ON / OFF する
#       メッシュもライトもインタラクトも、enableable インターフェースを持っていれば対象になる
# 置き方：エディターで entity に付け、interact_switch_component を付けた entity の子孫にする
switch_enable_component<public> := class<final_super>(component):

    # true にすると逆になる（スイッチ ON で消えて OFF で出る）
    @editable:
        ToolTip := SwitchEnableInvertTip
        Categories := array{InteractCategory}
    Invert<public>:logic = false

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Changed := switch_changed_event[SceneEvent]):
            On := logic{Changed.On <> Invert}

            for (Component : Entity.GetComponents(), Target := enableable[Component]):
                if (On?):
                    Target.Enable()
                else:
                    Target.Disable()
        false

# 役割：switch_changed_event を受け取ったら、同じ entity のキーフレーム移動を再生したり一時停止したりする
# 置き方：エディターで entity に付け、interact_switch_component を付けた entity の子孫にする
# 同じ entity：keyframed_movement_component（公式）、keyframe_loop_component（PlayOnStart は false にする）
switch_keyframe_component<public> := class<final_super>(component):

    # true にすると逆になる（スイッチ ON で止まり OFF で動く）
    @editable:
        ToolTip := SwitchKeyframeInvertTip
        Categories := array{InteractCategory}
    Invert<public>:logic = false

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Changed := switch_changed_event[SceneEvent], Movement := Entity.GetComponent[keyframed_movement_component]):
            if (Changed.On <> Invert):
                Movement.Play()
            else:
                Movement.Pause()
        false
