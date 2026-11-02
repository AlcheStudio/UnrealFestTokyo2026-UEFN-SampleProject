using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Abilities }
using { /Fortnite.com/Characters }
using { ZoneSystem }

# アビリティが使われた
# 向き：ability_pad_component がパッドの entity から SendDown。受け手：同じ entity と子孫の ability_*_effect_component。消費しない（効果を何個並べても全部に届く）
ability_used_event<public> := class(scene_event):
    # 送り元のパッド
    Pad<public>:ability_pad_component
    # アビリティを使った人
    Agent<public>:agent
    # アビリティを使った entity（パッドに乗ったプレイヤーのキャラクター。効果の対象）
    Instigator<public>:entity
    # 使った人のキャラクター
    Character<public>:fort_character
    # 効果が続く秒数（クールダウンと同じ）
    DurationSeconds<public>:float

# Verse で作るアビリティ（中身の無い最小の例）
#   ability は「コンテキストの型」と「効果の型」を型パラメーターで受け取るクラス。ここではどちらも公式の基本の型を渡している
#   MakeContext / MakeAbility で、使うたびに作るコンテキストと効果の entity を決める
tutorial_ability<public> := class(ability(ability_context, ability_effect)):
    MakeContext<override>()<transacts>:ability_context = ability_context{}
    MakeAbility<override>()<transacts>:ability_effect = ability_effect{}

# 役割：パッドに乗ったプレイヤーを使い手として tutorial_ability を Use し、ability_used_event を SendDown で流す
#       Cooldown 秒たったら効果を Cancel して終わらせ、また乗れるようになる
#       何が起きるかは同じ entity（または子孫）に付けた ability_*_effect_component で決まる
#       出入りの検知は同じ entity の volume_detector_component に任せ、volume_entered_event を OnReceive で受け取る
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component、ability_*_effect_component
ability_pad_component<public> := class<final_super>(component):

    # もう一度使えるまでの秒数（効果が続く秒数も兼ねる）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := PadCooldownTip
        Categories := array{AbilityCategory}
    Cooldown<public>:float = 3.0

    Ability<private>:tutorial_ability = tutorial_ability{}
    # 使っている最中は乗っても何もしない
    var Busy<private>:logic = false
    # 終わるときに効果を止める合図
    StopSignal<private>:event() = event(){}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("ability_pad")

    # 自分の entity のボリュームに入った人だけを使い手にする。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if:
            Entered := volume_entered_event[SceneEvent]
            Entered.Volume = Entity
            not Busy?
            Instigator := Entered.Character.GetEntity[]
        then:
            spawn{Use(Entered.Player, Entered.Character, Instigator)}
        false

    OnEndSimulation<override>():void =
        StopSignal.Signal()
        (super:)OnEndSimulation()

    Use<private>(Player:player, Character:fort_character, Instigator:entity)<suspends>:void =
        set Busy = true
        defer:
            set Busy = false

        Context := Ability.MakeContext()
        set Context.Instigator = option{Instigator}

        # Use は取り消せない処理なので if の条件（失敗コンテキスト）の外で呼ぶ
        if (Ability.CanUse[Entity, Context]):
            Used := Ability.Use(Entity, Context)
            if (Effect := Used?):
                Entity.AreaPrint("[ability_pad] アビリティを使った")
                Entity.SendDown(ability_used_event{Pad := Self, Agent := Player, Instigator := Instigator, Character := Character, DurationSeconds := Cooldown})

                race:
                    Sleep(Cooldown)
                    StopSignal.Await()

                if (Effect.AbilityComponent.Cancel[ability_ended{}]):
                    Entity.AreaPrint("[ability_pad] アビリティが終わった")
