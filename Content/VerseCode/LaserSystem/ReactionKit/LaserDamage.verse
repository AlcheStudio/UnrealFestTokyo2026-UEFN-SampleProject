using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { UtilitySystem }

# 役割：レーザーでキャラクターを狙っているあいだ、Interval 秒ごとにダメージを与える
#       狙い始め（laser_locked_event）で始め、止まると（laser_released_event）やめる
# 置き方：エディターで entity に付ける
# 同じ entity：laser_eye_component
laser_damage_reaction_component<public> := class(laser_reaction_component):

    # 1 回のダメージ
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := DamageReactionAmountTip
        Categories := array{LaserCategory}
    Amount<public>:float = 5.0

    # ダメージを与える間隔（秒）
    @editable_number(float):
        MinValue := option{0.1}
        MaxValue := option{60.0}
        ToolTip := DamageReactionIntervalTip
        Categories := array{LaserCategory}
    Interval<public>:float = 0.5

    LockedEvent<private>:event(fort_character) = event(fort_character){}
    ReleasedEvent<private>:event() = event(){}

    OnSimulate<override>()<suspends>:void =
        loop:
            Character := LockedEvent.Await()

            race:
                ReleasedEvent.Await()
                loop:
                    Character.Damage(Amount)
                    Sleep(Interval)

    OnLocked<override>(Aim:laser_aim):void =
        if (Character := Aim.Character?):
            LockedEvent.Signal(Character)

    OnReleased<override>():void =
        ReleasedEvent.Signal()
