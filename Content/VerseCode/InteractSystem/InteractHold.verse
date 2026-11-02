using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { UtilitySystem }
using { ZoneSystem }

# 役割：同じ entity の interactable_component を長押ししたときの 3 つのイベント（押し始め / 完了 / 途中で離した）を受け取り、
#       状態ごとにキューブを塗り分け、完了時に押していた秒数を Print して switch_changed_event{On := true} を SendDown する
#       （StartedEvent は長押しの「押し始め」に届く。完了は SucceededEvent）
# 置き方：エディターで entity に付け、basic_interactable_component の Interact Duration を 0 より大きくする
# 同じ entity：basic_interactable_component（公式）、SM_TutorialCube
# 子：switch_light_component / switch_keyframe_component など、switch_changed_event を受け取るコンポーネント
interact_hold_component<public> := class<final_super>(component):

    # 待機中（押していない / 途中で離した）の色
    @editable:
        ToolTip := InteractHoldIdleColorTip
        Categories := array{InteractCategory}
    IdleColor<public>:color = color{R := 0.35, G := 0.35, B := 0.35}

    # 押している間の色
    @editable:
        ToolTip := InteractHoldHoldColorTip
        Categories := array{InteractCategory}
    HoldColor<public>:color = color{R := 1.0, G := 0.8, B := 0.1}

    # 長押しが完了したときの色
    @editable:
        ToolTip := InteractHoldDoneColorTip
        Categories := array{InteractCategory}
    DoneColor<public>:color = color{R := 0.1, G := 1.0, B := 0.2}

    var StartedAt<private>:float = 0.0
    var Subscriptions<private>:[]cancelable = array{}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.PaintCube(IdleColor)

        if (Interactable := Entity.GetComponent[interactable_component]):
            set Subscriptions = array:
                Interactable.StartedEvent.Subscribe(OnStarted)
                Interactable.SucceededEvent.Subscribe(OnSucceeded)
                Interactable.CanceledEvent.Subscribe(OnCanceled)

    OnEndSimulation<override>():void =
        for (Subscription : Subscriptions):
            Subscription.Cancel()
        set Subscriptions = array{}

        (super:)OnEndSimulation()

    # 押し始め（長押しの開始時点で届く）
    OnStarted<private>(Agent:agent):void =
        set StartedAt = GetSimulationElapsedTime()
        Entity.AreaPrint("[interact_hold] 押し始め")
        Entity.PaintCube(HoldColor)

    # 長押しが完了した。押し始めからの秒数（≒ Interact Duration）を表示し、スイッチ ON として子孫へ流す
    OnSucceeded<private>(Agent:agent):void =
        Entity.AreaPrint("[interact_hold] 完了：{GetSimulationElapsedTime() - StartedAt} 秒")
        Entity.PaintCube(DoneColor)
        Entity.SendDown(switch_changed_event{Switch := Entity, On := true})

    # 完了前に離した
    OnCanceled<private>(Agent:agent):void =
        Entity.AreaPrint("[interact_hold] 途中で離した")
        Entity.PaintCube(IdleColor)
