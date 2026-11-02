using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/HealthPipeline }
using { UtilitySystem }
using { ZoneSystem }

# このキューブ専用の体力プール（プールは tag の種類で見分ける）
breakable_cube_pool_tag<public> := class(health_pool_tag){}

# 役割：entity に自分の体力プール（health_component）を持たせ、ダメージで色が変わり、0 で消えて RespawnSeconds 秒後に戻る
#       ダメージは health_pipeline の damage_event として SendUp で届く（送り手は damage_zone_component など）
# 置き方：エディターで entity に付ける
# 同じ entity：SM_TutorialCube（health_component は無ければ実行時に足す）
breakable_cube_component<public> := class<final_super>(component):

    # 体力の最大値
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := BreakableCubeMaxHealthTip
        Categories := array{HealthCategory}
    MaxHealth<public>:float = 100.0

    # 体力が満タンのときの色
    @editable:
        ToolTip := BreakableCubeFullColorTip
        Categories := array{HealthCategory}
    FullColor<public>:color = color{R := 0.2, G := 0.9, B := 0.3}

    # 体力が 0 に近いときの色
    @editable:
        ToolTip := BreakableCubeEmptyColorTip
        Categories := array{HealthCategory}
    EmptyColor<public>:color = color{R := 0.9, G := 0.1, B := 0.1}

    # 消えてから戻るまでの秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := BreakableCubeRespawnSecondsTip
        Categories := array{HealthCategory}
    RespawnSeconds<public>:float = 3.0

    var Subscriptions<private>:[]cancelable = array{}
    # 終わるときに、復活待ちを止める合図
    StopSignal<private>:event() = event(){}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (not Entity.GetComponent[health_component]):
            Entity.AddComponents(array{health_component{Entity := Entity}})

        if (Health := Entity.GetComponent[health_component]):
            # このキューブ用のプールを自分のタグで足す（ほかのプールがあっても取り違えない）
            if (not Health.GetHealthPool[breakable_cube_pool_tag]):
                Health.AddHealthPool(health_pool_entry{Tag := breakable_cube_pool_tag{}, CurrentValue := MaxHealth, MaxValue := MaxHealth})
            set Subscriptions = array:
                Health.OnDamaged.Subscribe(OnDamaged)
                Health.OnDied.Subscribe(OnDied)

        Entity.PaintCube(FullColor)

    OnEndSimulation<override>():void =
        StopSignal.Signal()

        for (Subscription : Subscriptions):
            Subscription.Cancel()
        set Subscriptions = array{}

        (super:)OnEndSimulation()

    # 残り体力（プールが無ければ 0）
    GetHealth<public>()<transacts>:float =
        if (Health := Entity.GetComponent[health_component], Pool := Health.GetHealthPool[breakable_cube_pool_tag]) then Pool.CurrentValue else 0.0

    # 残り体力の割合で FullColor と EmptyColor のあいだの色に塗る
    OnDamaged<private>(Result:health_adjustment_result):void =
        Ratio := if (MaxHealth > 0.0) then Clamp(GetHealth() / MaxHealth, 0.0, 1.0) else 0.0

        Entity.PaintCube(LerpColor(EmptyColor, FullColor, Ratio))

        Entity.AreaPrint("[breakable_cube] 残り {GetHealth()} / {MaxHealth}")

    OnDied<private>():void =
        Entity.AreaPrint("[breakable_cube] 壊れた。{RespawnSeconds} 秒後に戻る")
        SetMeshShown(false)
        spawn{Respawn()}

    Respawn<private>()<suspends>:void =
        race:
            Sleep(RespawnSeconds)
            StopSignal.Await()

        if (Health := Entity.GetComponent[health_component], Pool := Health.GetHealthPool[breakable_cube_pool_tag]):
            set Pool.CurrentValue = MaxHealth

        Entity.PaintCube(FullColor)
        SetMeshShown(true)

    SetMeshShown<private>(Shown:logic):void =
        if (Mesh := Entity.GetComponent[mesh_component]):
            set Mesh.Visible = Shown
            set Mesh.Collidable = Shown
