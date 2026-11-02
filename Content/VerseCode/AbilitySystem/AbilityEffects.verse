using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/SpatialMath }
using { /Fortnite.com/Characters }
using { UtilitySystem }

# ability_used_event を受け取って何かをする「効果」のコンポーネントたち
# どれもパッドの entity（または子孫）に付ける。付け替えるだけでアビリティの効果が変わる

# 役割：使ったプレイヤーの体力を Amount 回復する
# 置き方：エディターで ability_pad_component の entity か、その子孫に付ける
ability_heal_effect_component<public> := class<final_super>(component):

    # 回復量
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := HealEffectAmountTip
        Categories := array{AbilityCategory}
    Amount<public>:float = 30.0

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Used := ability_used_event[SceneEvent], Character := Used.Character):
            Character.Heal(Amount)
        false

# 役割：使ったプレイヤーに Amount のダメージを与える
# 置き方：エディターで ability_pad_component の entity か、その子孫に付ける
ability_damage_effect_component<public> := class<final_super>(component):

    # ダメージ量
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := DamageEffectAmountTip
        Categories := array{AbilityCategory}
    Amount<public>:float = 20.0

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Used := ability_used_event[SceneEvent], Character := Used.Character):
            Character.Damage(Amount)
        false

# 役割：使ったプレイヤーを上へ打ち上げる（速さを直接入れる）
# 置き方：エディターで ability_pad_component の entity か、その子孫に付ける
ability_launch_effect_component<public> := class<final_super>(component):

    # 打ち上げる速さ（メートル / 秒）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{200.0}
        ToolTip := LaunchEffectLaunchSpeedTip
        Categories := array{AbilityCategory}
    LaunchSpeed<public>:float = 20.0

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Used := ability_used_event[SceneEvent], Character := Used.Character):
            Character.SetLinearVelocity(vector3{Up := LaunchSpeed})
        false

# 役割：効果が続いているあいだ、同じ entity のキューブを ActiveColor に光らせ、終わったら IdleColor に戻す
#       OnReceive は待てないので、時間のかかる処理は spawn で別の流れとして動かす。終わるときは StopSignal で止めて色を戻す
# 置き方：エディターで ability_pad_component の entity か、その子孫に付ける
# 同じ entity：SM_TutorialCube か SM_TutorialVolumeCube
ability_glow_effect_component<public> := class<final_super>(component):

    # 効果中の色
    @editable:
        ToolTip := GlowEffectActiveColorTip
        Categories := array{AbilityCategory}
    ActiveColor<public>:color = color{R := 1.0, G := 0.3, B := 1.0}

    # 使える状態の色
    @editable:
        ToolTip := GlowEffectIdleColorTip
        Categories := array{AbilityCategory}
    IdleColor<public>:color = color{R := 0.2, G := 0.6, B := 1.0}

    # 光っている最中か（重ねて光らせない）
    var Glowing<private>:logic = false
    # 終わるときに光りを止める合図
    StopSignal<private>:event() = event(){}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.PaintCube(IdleColor)

    OnEndSimulation<override>():void =
        StopSignal.Signal()
        Entity.PaintCube(IdleColor)
        (super:)OnEndSimulation()

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Used := ability_used_event[SceneEvent], not Glowing?):
            spawn{Glow(Used.DurationSeconds)}
        false

    Glow<private>(DurationSeconds:float)<suspends>:void =
        set Glowing = true
        defer:
            set Glowing = false
            Entity.PaintCube(IdleColor)

        Entity.PaintCube(ActiveColor)

        race:
            Sleep(DurationSeconds)
            StopSignal.Await()
