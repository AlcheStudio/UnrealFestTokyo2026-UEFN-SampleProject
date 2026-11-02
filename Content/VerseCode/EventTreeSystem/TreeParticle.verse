using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Assets }

# 役割：tree_node_state_event を受け取ったら、状態（成功 / 失敗 / 未到達）ごとに指定したパーティクルを出す
#       未設定の状態では何も出さない
# 置き方：エディターで entity に付ける
# 同じ entity：tree_node_component
tree_particle_component<public> := class<final_super>(component):

    # 成功（イベントを通した）ときに出すパーティクル
    @editable:
        ToolTip := ParticleSucceededParticleTip
        Categories := array{EventTreeCategory}
    SucceededParticle<public>:?particle_system = false

    # 失敗（イベントを止めた）ときに出すパーティクル
    @editable:
        ToolTip := ParticleFailedParticleTip
        Categories := array{EventTreeCategory}
    FailedParticle<public>:?particle_system = false

    # 未到達（イベントが届いていない）ときに出すパーティクル
    @editable:
        ToolTip := ParticleUnreachedParticleTip
        Categories := array{EventTreeCategory}
    UnreachedParticle<public>:?particle_system = false

    # entity の位置からどれだけ上に出すか（cm）
    @editable_number(float):
        MinValue := option{-10000.0}
        MaxValue := option{10000.0}
        ToolTip := ParticleHeightTip
        Categories := array{EventTreeCategory}
    Height<public>:float = 120.0

    # 今出しているパーティクル（次の状態が届いたら Cancel して消す）
    var Spawned<private>:?cancelable = false

    OnEndSimulation<override>():void =
        Clear()
        (super:)OnEndSimulation()

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (StateEvent := tree_node_state_event[SceneEvent]):
            Clear()
            case (StateEvent.State):
                tree_node_state.Succeeded => Spawn(SucceededParticle)
                tree_node_state.Failed => Spawn(FailedParticle)
                tree_node_state.Unreached => Spawn(UnreachedParticle)
        false

    Spawn<private>(Particle:?particle_system):void =
        if (Asset := Particle?):
            Position := Entity.GetGlobalTransform().Translation + vector3{Up := Height}
            set Spawned = option{SpawnParticleSystem(Asset, Position)}

    Clear<private>():void =
        if (Previous := Spawned?):
            Previous.Cancel()

        set Spawned = false
