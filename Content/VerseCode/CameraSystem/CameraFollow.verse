using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Fortnite.com/SceneGraphCameras }

# camera_target_event を受け取って、同じ entity のカメラに「プレイヤーを追うモディファイアー」を積むコンポーネントたち
# どれを付けるかで、同じカメラが「見下ろし」にも「回り込み」にもなる
# モディファイアーは入ったプレイヤーごとに積み、その人が出たらその人の分だけ外す
# 置き方：エディターで camera_zone_component の子 entity（カメラを付けた entity）に付ける

# 役割：プレイヤーごとに積んだモディファイアーを覚えておき、入退出に合わせて積む / 外す基底。どのモディファイアーかは派生（FollowKit）が MakeModifier で決める
# 置き方：直接は置かない（派生を置く）
# 同じ entity：camera_component
camera_follow_component<public> := class<abstract><final_super>(component):

    var Added<private>:[entity]cancelable = map{}

    # Target を追うモディファイアーを作る
    MakeModifier<protected>(Target:entity):camera_modifier

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Changed := camera_target_event[SceneEvent]):
            Remove(Changed.Target)

            if (Changed.Entered?, Camera := Entity.GetComponent[camera_component]):
                Handle := Camera.CameraModifiers.AddModifier(MakeModifier(Changed.Target), Camera.CameraModifiers.LastPosition)
                Stored := option{set Added[Changed.Target] = Handle}
        false

    OnEndSimulation<override>():void =
        for (Target -> Handle : Added):
            Handle.Cancel()
        set Added = map{}

        (super:)OnEndSimulation()

    Remove<private>(Target:entity):void =
        if (Handle := Added[Target]):
            Handle.Cancel()

            var Remaining:[entity]cancelable = map{}
            for (Key -> Value : Added, Key <> Target):
                Kept := option{set Remaining[Key] = Value}

            set Added = Remaining
