using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/HealthPipeline }
using { ZoneSystem }

# 役割：プレイヤーが入るたびに、breakable_cube_component を持つ entity（同じ entity か、最初に見つかった子）へ Amount の damage_event を SendUp する
#       health_component がイベントを受け取って体力を減らし、OnDamaged / OnDied を鳴らす
#       出入りの検知は同じ entity の volume_detector_component に任せ、volume_entered_event を OnReceive で受け取る
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ（SM_TutorialVolumeCube）、volume_detector_component。キューブは子 entity に置く
damage_zone_component<public> := class<final_super>(component):

    # 1 回入るごとに与えるダメージ
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := DamageZoneAmountTip
        Categories := array{HealthCategory}
    Amount<public>:float = 25.0

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("damage_zone")

    # 自分の entity のボリュームに入ったときだけダメージを送る。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            SendDamage(Entered.Player)
        false

    SendDamage<private>(Player:player):void =
        if (Target := FindCube[]):
            # 与えた人（キャラクター entity）は、detector が知っていれば添える
            Instigator:?entity = option{Entity.GetComponent[volume_detector_component].FindCharacterEntity[Player]}

            Damage := damage_event:
                Context := health_adjustment_context{Instigator := Instigator}
                Entries := array{health_adjustment_entry{HealthDelta := Amount}}

            Target.Entity.SendUp(Damage)
            Entity.AreaPrint("[damage_zone] {Amount} のダメージを送った（残り {Target.GetHealth()}）")
        else:
            Entity.AreaPrint("[damage_zone] breakable_cube_component が見つからない")

    # 同じ entity か、最初に見つかった子 entity の breakable_cube_component
    FindCube<private>()<decides><transacts>:breakable_cube_component =
        if (Cube := Entity.GetComponent[breakable_cube_component]):
            Cube
        else:
            Found := for (Child : Entity.GetEntities(), Cube := Child.GetComponent[breakable_cube_component]):
                Cube
            Found[0]
