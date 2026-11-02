using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { UtilitySystem }
using { ZoneSystem }

# カメラゾーンにプレイヤーが出入りした
# 向き：camera_zone_component がゾーンの entity から SendDown。受け手：子 entity の camera_*_follow_component / camera_layer_bob_component。消費しない
camera_target_event<public> := class(scene_event):
    # 送り元のゾーン
    Zone<public>:camera_zone_component
    # 出入りしたプレイヤー
    Agent<public>:agent
    # 出入りしたプレイヤーのキャラクター entity（追従の対象）
    Target<public>:entity
    # true：入った / false：出た
    Entered<public>:logic

# 役割：ゾーンに入ったプレイヤーのカメラを、子 entity に付けたカメラに切り替える。出たら元に戻す
#       プレイヤーの camera_director_component に AddCamera で足し、戻り値の cancelable を Cancel して外す
#       使うカメラの種類（perspective / orthographic / physical）は子 entity のコンポーネントを付け替えて決める
#       出入りは camera_target_event として SendDown でも流す（追従用の camera_*_follow_component が使う）
#       出入りの検知は同じ entity の volume_detector_component に任せ、volume_entered_event / volume_exited_event を OnReceive で受け取る
#       追従の対象（キャラクター entity）は入った瞬間に detector の FindCharacterEntity で取る。分からなければ追従は無しでカメラだけ切り替える
# 置き方：エディターでゾーンの entity に付け、子 entity を 1 つ作ってカメラコンポーネントを付ける
# 同じ entity：OverlapAll のメッシュ、volume_detector_component
# 子：カメラコンポーネント（と camera_*_follow_component など）を付けた entity
camera_zone_component<public> := class<final_super>(component):

    # カメラの優先度（高いほど優先される）
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{1000}
        ToolTip := ZonePriorityTip
        Categories := array{CameraCategory}
    Priority<public>:int = 100

    # プレイヤーごとに、足したカメラを外すための cancelable を覚えておく
    var Active<private>:[player]cancelable = map{}
    # プレイヤーごとの追従の対象（出たときの camera_target_event に使う。detector は出たあとはキャラクター entity を返さない）
    var Targets<private>:[player]entity = map{}
    # 「キャラクター entity が分からない」を 1 回だけ Print するため
    var WarnedNoTarget<private>:logic = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Entity.CheckVolumeDetector("camera_zone")

    # 自分の entity のボリュームの出入りだけに反応する。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Entered.Volume = Entity):
            HandleEntered(Entered.Player)
        else if (Exited := volume_exited_event[SceneEvent], Exited.Volume = Entity):
            HandleExited(Exited.Player)
        false

    HandleEntered<private>(Player:player):void =
        if:
            not Active[Player]
            # director はキャラクターの entity ではなく、agent（プレイヤー自体も entity）の子孫にある
            Director := Player.FindCameraDirector[]
            Camera := FindZoneCamera[]
            Added := Director.AddCamera[Camera, Priority]
            set Active[Player] = Added
        then:
            if (Detector := Entity.GetComponent[volume_detector_component], Target := Detector.FindCharacterEntity[Player], set Targets[Player] = Target):
                Entity.SendDown(camera_target_event{Zone := Self, Agent := Player, Target := Target, Entered := true})
            else if (not WarnedNoTarget?):
                set WarnedNoTarget = true
                Entity.AreaPrint("[camera_zone] キャラクターの entity が分からないので、追従なしでカメラだけ切り替えた")

    HandleExited<private>(Player:player):void =
        if (Added := Active[Player]):
            Added.Cancel()
            set Active = Active.WithoutPlayer(Player)

            if (Target := Targets[Player]):
                set Targets = Targets.WithoutPlayer(Player)
                Entity.SendDown(camera_target_event{Zone := Self, Agent := Player, Target := Target, Entered := false})

    # 子 entity のうち、最初に見つかったカメラを使う（無ければ失敗）
    FindZoneCamera<private>()<decides><transacts>:camera_component =
        first:
            Child : Entity.GetEntities()
            Child.GetComponent[camera_component]

# プレイヤーの camera_director_component を探す（キャラクターの entity ではなく、プレイヤー本体の entity の子孫にある）。無ければ失敗する
(Player:player).FindCameraDirector<internal>()<decides><transacts>:camera_director_component =
    first:
        Director : Player.FindDescendantComponents(camera_director_component)
        Director
