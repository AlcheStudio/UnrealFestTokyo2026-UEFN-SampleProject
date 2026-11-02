using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# スイッチの ON / OFF が切り替わった（開始時にも今の状態が 1 回届く）
# 向き：interact_switch_component / interact_hold_component がスイッチの entity から SendDown。受け手：子孫の switch_*_component。消費しない
switch_changed_event<public> := class(scene_event):
    # 送り元のスイッチの entity
    Switch<public>:entity
    On<public>:logic

# 役割：同じ entity の interactable_component でインタラクトされるたびに ON / OFF を切り替え、
#       switch_changed_event を SendDown で子孫へ流す（開始時にも今の状態を一度流す）
# 置き方：エディターで entity に付ける
# 同じ entity：basic_interactable_component（公式）、インタラクトで狙えるメッシュ
# 子：switch_light_component / switch_keyframe_component など、switch_changed_event を受け取るコンポーネント
interact_switch_component<public> := class<final_super>(component):

    # 開始時に ON にしておくか
    @editable:
        ToolTip := InteractSwitchStartOnTip
        Categories := array{InteractCategory}
    StartOn<public>:logic = false

    var On<private>:logic = false
    var Subscription<private>:?cancelable = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        set On = StartOn

        if (Interactable := Entity.GetComponent[interactable_component]):
            set Subscription = option{Interactable.SucceededEvent.Subscribe(OnInteracted)}

    OnSimulate<override>()<suspends>:void =
        # 子孫のコンポーネントの準備が終わるのを 1 フレーム待ってから最初の状態を流す
        TickEvents.PrePhysics.Await()
        Entity.SendDown(switch_changed_event{Switch := Entity, On := On})

    OnEndSimulation<override>():void =
        if (Previous := Subscription?):
            Previous.Cancel()
        set Subscription = false

        (super:)OnEndSimulation()

    OnInteracted<private>(Agent:agent):void =
        set On = logic{not On?}
        Entity.SendDown(switch_changed_event{Switch := Entity, On := On})
