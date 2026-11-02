using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/UI }

# 役割：展示に要らない Fortnite 標準の HUD（ミニマップ・建築・チーム情報など）を、プレイヤーごとに隠す
#       何を隠すかはチェックボックスで選ぶ。体力、インタラクトの案内、手持ちのアイテム欄は、展示で使うので隠さない
#       島全体の設定（HideElements）ではなくプレイヤー単位（HideElementsForPlayer）で隠し、終わるときは自分が隠した人だけ戻す
#       いるプレイヤー全員に隠してから、あとから入ってきた人にも同じように隠す
# 置き方：エディターで entity に 1 つだけ付ける
hud_cleanup_component<public> := class<final_super>(component):

    # 体力とシールド（ダメージやアビリティの展示で見るので、既定では隠さない）
    @editable:
        ToolTip := HudCleanupHealthTip
        Categories := array{LayoutCategory}
    HideHealth<public>:logic = false

    # ミニマップと地図の案内
    @editable:
        ToolTip := HudCleanupMinimapTip
        Categories := array{LayoutCategory}
    HideMinimap<public>:logic = true

    # 建築メニューと素材
    @editable:
        ToolTip := HudCleanupBuildTip
        Categories := array{LayoutCategory}
    HideBuild<public>:logic = true

    # チーム情報・人数・撃破数
    @editable:
        ToolTip := HudCleanupTeamTip
        Categories := array{LayoutCategory}
    HideTeamInfo<public>:logic = true

    # ラウンドとストームの情報
    @editable:
        ToolTip := HudCleanupRoundTip
        Categories := array{LayoutCategory}
    HideRoundInfo<public>:logic = true

    # 経験値
    @editable:
        ToolTip := HudCleanupExperienceTip
        Categories := array{LayoutCategory}
    HideExperience<public>:logic = true

    # 拾ったアイテムの流れ
    @editable:
        ToolTip := HudCleanupPickupTip
        Categories := array{LayoutCategory}
    HidePickupStream<public>:logic = false

    # 自分が隠したプレイヤー（終わるときに戻す）
    var Controlled<private>:[player]logic = map{}

    # 開始直後は playspace がまだ取れないことがあるので、取れるまでこの間隔で待つ（秒）
    PlayspaceRetrySeconds<private>:float = 1.0

    OnSimulate<override>()<suspends>:void =
        loop:
            if (Playspace := Entity.GetPlayspaceForEntity[]):
                for (Player : Playspace.GetPlayers()):
                    HideFor(Playspace, Player)

                loop:
                    Added := Playspace.PlayerAddedEvent().Await()
                    HideFor(Playspace, Added)
            else:
                Sleep(PlayspaceRetrySeconds)

    OnEndSimulation<override>():void =
        if (Playspace := Entity.GetPlayspaceForEntity[]):
            Elements := MakeElements()
            for (Player -> Flag : Controlled):
                Playspace.GetHUDController().ResetElementsForPlayer(Player, Elements)
        set Controlled = map{}

        (super:)OnEndSimulation()

    HideFor<private>(Playspace:fort_playspace, Player:player):void =
        Elements := MakeElements()

        if (Elements.Length > 0):
            Playspace.GetHUDController().HideElementsForPlayer(Player, Elements)
            if (set Controlled[Player] = true) {}

    # チェックの入った項目を、公式 API に渡す形（hud_element_identifier の配列）にする
    MakeElements<private>():[]hud_element_identifier =
        var Elements:[]hud_element_identifier = array{}

        if (HideHealth?):
            set Elements += array{creative_hud_identifier_health{}, creative_hud_identifier_health_numbers{}, creative_hud_identifier_shields{}, creative_hud_identifier_shield_numbers{}}
        if (HideMinimap?):
            set Elements += array{creative_hud_identifier_minimap{}, creative_hud_identifier_map_prompts{}}
        if (HideBuild?):
            set Elements += array{creative_hud_identifier_build_menu{}, creative_hud_identifier_crafting_resources{}}
        if (HideTeamInfo?):
            set Elements += array{creative_hud_identifier_team_info{}, creative_hud_identifier_player_count{}, creative_hud_identifier_elimination_counter{}}
        if (HideRoundInfo?):
            set Elements += array{creative_hud_identifier_round_info{}, creative_hud_identifier_round_timer{}, creative_hud_identifier_storm_timer{}, creative_hud_identifier_storm_notifications{}}
        if (HideExperience?):
            set Elements += array{creative_hud_identifier_experience_level{}, creative_hud_identifier_experience_supercharged{}, creative_hud_identifier_experience_ui{}}
        if (HidePickupStream?):
            set Elements += array{creative_hud_identifier_pickup_stream{}}

        Elements
