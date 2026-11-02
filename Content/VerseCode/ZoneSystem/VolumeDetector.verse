using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { VerseAsset.Mesh }
using { UtilitySystem }

# プレイヤーがボリュームに入った
# 向き：volume_detector_component がボリュームの entity から SendUp。受け手：同じ entity と祖先の component。消費しない
#       受け手は Volume で「どのボリュームの知らせか」を見分ける（自分の entity のボリュームだけに反応するなら Volume = Entity）
volume_entered_event<public> := class(scene_event):
    # 入ったプレイヤー
    Player<public>:player
    # 入ったプレイヤーのキャラクター
    Character<public>:fort_character
    # 送り元のボリュームの entity
    Volume<public>:entity

# プレイヤーがボリュームから出た（キャラクターは入ったときのもの）
# 向き：volume_entered_event と同じ。消費しない
volume_exited_event<public> := class(scene_event):
    Player<public>:player
    Character<public>:fort_character
    Volume<public>:entity

# 役割：同じ entity のメッシュの範囲にプレイヤーが入った / 出たことを、1 か所でまとめて調べて知らせる
#       ボリュームを使う展示はすべてこれを同じ entity に置き、自分では重なりを調べない（継承もしない）
#       PollInterval 秒ごとに 2 通りで調べ、どちらかで見つかれば「中にいる」とする
#         問い合わせ：FindOverlapHits で今重なっている entity を調べる（キャラクターの entity も分かる）
#         位置：プレイヤーのキャラクターの位置が、メッシュの範囲（100cm の箱 × Scale、底面が原点）に入っているか
#               SM_TutorialCylinder なら円柱、それ以外は箱として調べる。回転は見ない
#       変わったときだけ volume_entered_event / volume_exited_event を SendUp し、PlayerEnteredEvent / PlayerExitedEvent も鳴らす
#       ラウンドが始まったら調べ始め、ラウンドが終わると止まる（fort_round_manager）
#       ラウンドが終わるときとシミュレーションが終わるときは、まだ中にいるプレイヤーぶんの volume_exited_event を送ってから片付ける
# 置き方：エディターで entity に付ける
# 同じ entity：OverlapAll のメッシュ（SM_TutorialVolumeCube か SM_TutorialCylinder）、受け取り側の component
# 親：受け取り側の component（任意。SendUp は親にも届く）
# 外から：GetComponent で取り、GetPlayersInside / IsInside / InsideCount / FindCharacterEntity / WaitUntilLeft を使う
volume_detector_component<public> := class<final_super>(component):

    # 出入りを調べる間隔（秒）
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{60.0}
        ToolTip := VolumeDetectorPollIntervalTip
        Categories := array{ZoneCategory}
    PollInterval<public>:float = 0.25

    # 位置で調べるときに、範囲の上下に足す余裕（cm）。薄い床で使うときは大きくする
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{2000.0}
        ToolTip := VolumeDetectorHeightMarginTip
        Categories := array{ZoneCategory}
    HeightMargin<public>:float = 100.0

    PlayerEnteredEventInternal<private><final>:event(player) = event(player){}
    PlayerExitedEventInternal<private><final>:event(player) = event(player){}

    # プレイヤーが入った（Await / Subscribe する。Signal できるのはこの component だけ）
    PlayerEnteredEvent<public><final>:listenable(player) = MakeProxyListenable(PlayerEnteredEventInternal)

    # プレイヤーが出た（終わるときは、まだ中にいた人ぶんも届く）
    PlayerExitedEvent<public><final>:listenable(player) = MakeProxyListenable(PlayerExitedEventInternal)

    var Inside<private>:[player]fort_character = map{}
    # 中にいるプレイヤーのキャラクター entity
    var CharacterEntities<private>:[player]entity = map{}

    # ラウンドごとに RunRound を動かす購読 / ラウンド終了で全員を出す購読（OnEndSimulation で Cancel）
    var RoundSubscription<private>:?cancelable = false
    var RoundEndSubscription<private>:?cancelable = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Mesh := Entity.GetComponent[mesh_component]):
            # 重なりを取るので Collidable は true にする（OverlapAll のメッシュなのでプレイヤーは止まらない）
            set Mesh.Collidable = true
            set Mesh.Queryable = true

        set RoundSubscription = Entity.SubscribeRounds(RunRound)
        set RoundEndSubscription = Entity.SubscribeRoundEnds(LeaveAll)

    RunRound<private>()<suspends>:void =
        loop:
            Sleep(PollInterval)
            Poll()

    OnEndSimulation<override>():void =
        if (Subscription := RoundSubscription?):
            Subscription.Cancel()
        set RoundSubscription = false

        if (EndSubscription := RoundEndSubscription?):
            EndSubscription.Cancel()
        set RoundEndSubscription = false

        LeaveAll()

        (super:)OnEndSimulation()

    # まだ中にいるプレイヤー全員に、ふつうの退出（volume_exited_event と PlayerExitedEvent）を送って空にする
    LeaveAll<private>():void =
        for (Player -> Character : Inside):
            Entity.SendUp(volume_exited_event{Player := Player, Character := Character, Volume := Entity})
            PlayerExitedEventInternal.Signal(Player)

        set Inside = map{}
        set CharacterEntities = map{}

    # 今ボリュームにいるプレイヤー（並び順は決まっていない）
    GetPlayersInside<public>()<transacts>:[]player =
        for (Player -> Character : Inside):
            Player

    # 今ボリュームにいる人数
    InsideCount<public>()<transacts>:int =
        GetPlayersInside().Length

    # Player が今ボリュームの中にいれば成功する
    IsInside<public>(Player:player)<decides><transacts>:void =
        Inside[Player]

    # 中にいる Player のキャラクター entity（アビリティやカメラの対象に使う）。分からなければ失敗する
    FindCharacterEntity<public>(Player:player)<decides><transacts>:entity =
        CharacterEntities[Player]

    # Player が出るまで待つ（いなければすぐ戻る）
    WaitUntilLeft<public>(Player:player)<suspends>:void =
        if (Inside[Player]):
            loop:
                Left := PlayerExitedEvent.Await()
                if (Left = Player):
                    break

    # 今中にいるプレイヤーを調べ、前回と変わった人だけ Enter / Leave する
    Poll<private>():void =
        var Found:[player]fort_character = map{}
        var FoundEntities:[player]entity = map{}

        for (Hit : Entity.FindOverlapHits(), Other := Hit.TargetComponent.Entity, Character := Other.FindCharacter[], Player := player[Character.GetAgent[]]):
            if (set Found[Player] = Character, set FoundEntities[Player] = Other) {}

        if (Playspace := Entity.GetPlayspaceForEntity[]):
            Area := FromTransform(Entity.GetGlobalTransform())
            IsCylinder := if (Entity.GetComponent[SM_TutorialCylinder]) then true else false
            for (Player : Playspace.GetPlayers(), not Found[Player], Character := Player.GetFortCharacter[], Character.IsActive[]):
                if (IsInsideArea(Area, Character.GetTransform().Translation, IsCylinder)?):
                    if (set Found[Player] = Character) {}

        for (Player -> Character : Found, not Inside[Player]):
            Enter(Player, Character, option{FoundEntities[Player]})
        for (Player -> Character : Inside, not Found[Player]):
            Leave(Player)

    # 位置が範囲に入っているか（100cm の箱 × Scale、原点は底面中央。高さはキャラクターの中心が上に出るぶん HeightMargin の余裕を持たせる）
    IsInsideArea<private>(Area:transform, Position:vector3, IsCylinder:logic)<transacts>:logic =
        DeltaX := Position.X - Area.Translation.X
        DeltaY := Position.Y - Area.Translation.Y
        HalfX := 50.0 * Area.Scale.X
        HalfY := 50.0 * Area.Scale.Y
        # 円柱は X と Y を同じ Scale にして置く前提（半径は X の半分）
        InPlane := if (IsCylinder?) then (if (DeltaX * DeltaX + DeltaY * DeltaY <= HalfX * HalfX) then true else false) else (if (Abs(DeltaX) <= HalfX, Abs(DeltaY) <= HalfY) then true else false)

        if:
            InPlane?
            Position.Z >= Area.Translation.Z - HeightMargin
            Position.Z <= Area.Translation.Z + 100.0 * Area.Scale.Z + HeightMargin
        then:
            true
        else:
            false

    Enter<private>(Player:player, Character:fort_character, CharacterEntity:?entity):void =
        if (not Inside[Player], set Inside[Player] = Character):
            Body := if (Found := CharacterEntity?) then option{Found} else option{Character.GetEntity[]}
            if (Found := Body?, set CharacterEntities[Player] = Found) {}

            Entity.SendUp(volume_entered_event{Player := Player, Character := Character, Volume := Entity})
            PlayerEnteredEventInternal.Signal(Player)

    Leave<private>(Player:player):void =
        if (Character := Inside[Player]):
            set Inside = Inside.WithoutPlayer(Player)
            set CharacterEntities = CharacterEntities.WithoutPlayer(Player)

            Entity.SendUp(volume_exited_event{Player := Player, Character := Character, Volume := Entity})
            PlayerExitedEventInternal.Signal(Player)

# 同じ entity に volume_detector_component が無いことを Print で知らせる（受け取り側の置き忘れに気付くため）
NoVolumeDetectorPrint<public>(Label:string):void =
    Print("[{Label}] 同じ entity に volume_detector_component がありません。付けるまで出入りを受け取れません")

# 開始時に、同じ entity に volume_detector_component があるか確かめる（OnReceive で受け取る component が OnBeginSimulation で呼ぶ）
(InEntity:entity).CheckVolumeDetector<public>(Label:string):void =
    if (not InEntity.GetComponent[volume_detector_component]):
        NoVolumeDetectorPrint(Label)
