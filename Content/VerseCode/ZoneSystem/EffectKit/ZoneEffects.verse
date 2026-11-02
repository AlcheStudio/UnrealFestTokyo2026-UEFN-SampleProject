using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Input }
using { /UnrealEngine.com/Temporary }
using { /Fortnite.com/Characters }
using { UtilitySystem }

# このファイルのゾーンはどれも、出入りの検知を同じ entity の volume_detector_component に任せ、
# その volume_entered_event / volume_exited_event を OnReceive で受け取る（自分の entity のボリュームの知らせだけ。消費しない）

# 役割：入ったプレイヤーを Duration 秒その場に固める（PutInStasis）。向きは変えられる
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
stasis_zone_component<public> := class<final_super>(component):

    # 固める秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := StasisZoneDurationTip
        Categories := array{ZoneCategory}
    Duration<public>:float = 3.0

    # 終わるときに、固めている人を全員解放する合図
    StopSignal<private>:event() = event(){}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("stasis_zone")

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            Entered.Character.PutInStasis(stasis_args{AllowTurning := true, AllowFalling := true, AllowEmotes := true})
            spawn{Release(Entered.Character)}
        false

    OnEndSimulation<override>():void =
        StopSignal.Signal()
        (super:)OnEndSimulation()

    Release<private>(Character:fort_character)<suspends>:void =
        race:
            Sleep(Duration)
            StopSignal.Await()

        Character.ReleaseFromStasis()

# 役割：入っているあいだ、プレイヤーを透明にしてダメージを受けなくする（出たら戻す）
#       終わるときも、detector がまだ中にいる人ぶんの volume_exited_event を送るので元に戻る
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
ghost_zone_component<public> := class<final_super>(component):

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("ghost_zone")

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            Entered.Character.Hide()
            Entered.Character.SetVulnerability(false)
        else if (Exited := volume_exited_event[SceneEvent], Exited.Volume = Entity):
            Exited.Character.Show()
            Exited.Character.SetVulnerability(true)
        false

# 役割：入ったプレイヤーを、ゾーンのまわり Radius 以内のランダムな場所へ移す（GetRandomFloat）
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
random_teleport_zone_component<public> := class<final_super>(component):

    # 移す範囲の半径（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{20000.0}
        ToolTip := RandomTeleportZoneRadiusTip
        Categories := array{ZoneCategory}
    Radius<public>:float = 1500.0

    # 移す先として使わない距離（cm。ゾーンの中に戻らないように）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{20000.0}
        ToolTip := RandomTeleportZoneMinRadiusTip
        Categories := array{ZoneCategory}
    MinRadius<public>:float = 500.0

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("random_teleport_zone")

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            Teleport(Entered.Character)
        false

    Teleport<private>(Character:fort_character):void =
        Center := Entity.GetGlobalTransform().Translation
        Angle := GetRandomFloat(0.0, 2.0 * PiFloat)
        Reach := GetRandomFloat(MinRadius, Max(Radius, MinRadius))
        # 足元が床に埋まらないように、少し上げる
        Target := Center + vector3{Forward := Reach * Cos(Angle), Left := Reach * Sin(Angle), Up := 100.0}

        Moved := Character.TryTeleport(Target, IdentityRotation())
        if (not Moved?):
            Entity.AreaPrint("[random_teleport_zone] 移せなかった")

# 役割：入ったプレイヤーが今使っている操作方法（キーボードとマウス / ゲームパッド / タッチ）に合わせた案内を出す
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
input_method_zone_component<public> := class<final_super>(component):

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("input_method_zone")

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            ShowHint(Entered.Player)
        false

    ShowHint<private>(Player:player):void =
        if (Input := GetPlayerInput[Player]):
            Hint := case (Input.PreferredInputMethod):
                input_method.KeyboardAndMouse => "キーボードとマウス：E キーで調べる"
                input_method.Gamepad => "ゲームパッド：□ / X ボタンで調べる"
                input_method.Touch => "タッチ：画面のボタンで調べる"
                _ => "操作方法を判定できなかった"

            Entity.AreaPrint("[input_method_zone] {Hint}")
