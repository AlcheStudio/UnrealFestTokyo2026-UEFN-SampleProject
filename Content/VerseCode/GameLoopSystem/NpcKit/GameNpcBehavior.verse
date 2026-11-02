using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { StepKit }

# 役割：ゲームの NPC の振る舞い。動きは自分の entity から GetComponent で取った guard_actions_component で行う
#       NPC を倒す段階が動いているあいだは挑戦者を追いかけて攻撃し、それ以外はその場をうろつく
#       倒されたら、game_defeat_target_tag の付いた段階に NotifyDefeated で知らせる
#       段階（defeat_npc_step_component）はレベルに置かれていて動かないので、開始時に 1 回だけタグで探して覚える（ThinkInterval ごとに世界を探さない）
# 置き方：NPC キャラクター定義（Character Definition）の振る舞いに指定し、NPC スポナーで出す（ガードの種類にする）
game_npc_behavior<public> := class(npc_behavior):

    # 挑戦者からこの距離（cm）以内にとどまる
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10000.0}
        ToolTip := NpcBehaviorChaseRadiusTip
        Categories := array{GameLoopNpcCategory}
    ChaseRadius<public>:float = 800.0

    # 状況を見直す間隔（秒）
    @editable_number(float):
        MinValue := option{0.1}
        MaxValue := option{60.0}
        ToolTip := NpcBehaviorThinkIntervalTip
        Categories := array{GameLoopNpcCategory}
    ThinkInterval<public>:float = 2.0

    OnBegin<override>()<suspends>:void =
        if:
            NpcEntity := GetEntity[]
            Guard := NpcEntity.GetComponent[guard_actions_component]
            Character := GetAgent[].GetFortCharacter[]
        then:
            if (Step := FindDefeatStep[NpcEntity]):
                race:
                    block:
                        Character.EliminatedEvent().Await()
                        Step.NotifyDefeated()
                    Think(Guard, Step)
            else:
                # 段階が無ければ、倒されても数えず、うろつくだけ
                Print("[game_npc_behavior] game_defeat_target_tag の付いた段階が見つからない（うろつくだけにする）")
                loop:
                    RoamOnce(Guard)
        else:
            Print("[game_npc_behavior] guard_actions_component が見つからない（ガードの NPC にする）")

    Think<private>(Guard:guard_actions_component, Step:defeat_npc_step_component)<suspends>:void =
        loop:
            if (Target := Step.FindTarget[], TargetAgent := Step.FindTargetAgent[]):
                Guard.Tether(Target, ChaseRadius)

                # Attack は「相手を検知していること」が前提なので、先に相手の近くまで移動してから攻撃する
                race:
                    block:
                        Moved := Guard.NavigateTo(MakeNavigationTarget(TargetAgent), ?ReachRadius := 500.0)
                        Attacked := Guard.Attack(Target)
                        Sleep(ThinkInterval)
                    Sleep(ThinkInterval * 2.0)
            else:
                if (NpcEntity := GetEntity[]):
                    Guard.Tether(NpcEntity.GetGlobalTransform().Translation, ChaseRadius)
                RoamOnce(Guard)

    # ThinkInterval 秒だけうろつく（長引いても ThinkInterval で打ち切る）
    RoamOnce<private>(Guard:guard_actions_component)<suspends>:void =
        race:
            block:
                Guard.RoamAround()
                Sleep(ThinkInterval)
            Sleep(ThinkInterval)

    # レベルの中から、game_defeat_target_tag の付いた段階を探す（開始時に 1 回だけ呼ぶ）
    FindDefeatStep<private>(NpcEntity:entity)<decides><transacts>:defeat_npc_step_component =
        Simulation := NpcEntity.GetSimulationEntity[]

        first:
            Candidate : Simulation.FindDescendantEntitiesWithTag(game_defeat_target_tag)
            Candidate.GetComponent[defeat_npc_step_component]
