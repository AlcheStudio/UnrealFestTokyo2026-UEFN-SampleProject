using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Progression }
using { /Fortnite.com/Characters }
using { /Verse.org/Assets }
using { VerseAsset.UI }

# 役割：ジャンプした回数で進むクエストを渡す（fort_character.JumpedEvent）
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
jump_quest_component<public> := class(quest_giver_component):

    QuestIcon<override>()<transacts>:texture = T_IconQuestJump

    TrackProgress<override>(Player:player, Character:fort_character, Objective:progress_objective)<suspends>:void =
        var Count:float = 0.0

        loop:
            Character.JumpedEvent().Await()
            set Count += 1.0
            Objective.SetProgress(Count)

# 役割：しゃがんだ回数で進むクエストを渡す（fort_character.CrouchedEvent）
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
crouch_quest_component<public> := class(quest_giver_component):

    QuestIcon<override>()<transacts>:texture = T_IconQuestCrouch

    TrackProgress<override>(Player:player, Character:fort_character, Objective:progress_objective)<suspends>:void =
        var Count:float = 0.0

        loop:
            Crouched := Character.CrouchedEvent().Await()
            if (Crouched(1)?):
                set Count += 1.0
                Objective.SetProgress(Count)
