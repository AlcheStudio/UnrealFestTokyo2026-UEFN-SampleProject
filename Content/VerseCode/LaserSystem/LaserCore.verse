using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/SpatialMath }

# 狙う先。Point はレーザーの終わりの位置、Target は狙っている entity（場所だけを狙うときは false）
laser_aim<public> := class:
    Point<public>:vector3
    Target<public>:?entity = false
    # 狙っている相手のキャラクター（プレイヤーを狙うときだけ）
    Character<public>:?fort_character = false

# レーザーを出し始めた（狙う相手が替わったときも、止めた → 出し始めた の順で届く）
# 向き：laser_eye_component が目の entity から SendDown。受け手：同じ entity と子孫の laser_reaction_component の派生。消費しない
laser_locked_event<public> := class(scene_event):
    # 送り元の目
    Eye<public>:laser_eye_component
    Aim<public>:laser_aim

# レーザーを止めた
# 向き：laser_locked_event と同じ。消費しない
laser_released_event<public> := class(scene_event):
    Eye<public>:laser_eye_component

# 役割：目がどこを狙うかを決める基底。狙い方は派生（TargetKit）が FindAim で決める
# 置き方：直接は置かない（派生を置く）
# 同じ entity：laser_eye_component
laser_target_component<public> := class<abstract><final_super>(component):

    # 今狙う先。狙うものが無ければ失敗する（レーザーが消える）
    FindAim<public>()<decides><transacts>:laser_aim

# 役割：目が狙い始めた / 止めたときに何かをする基底。何をするかは派生（ReactionKit）が OnLocked / OnReleased で決める
#       laser_locked_event / laser_released_event を受け取って派生の穴を呼ぶだけ。イベントは消費しない
# 置き方：直接は置かない（派生を置く）
# 同じ entity：laser_eye_component（派生どうしは 1 entity に 1 つまで）
laser_reaction_component<public> := class<abstract><final_super>(component):

    # 派生用：狙い始めた（Aim.Target が false なら場所だけを狙っている）
    OnLocked<protected>(Aim:laser_aim):void = {}

    # 派生用：狙うのをやめた
    OnReleased<protected>():void = {}

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Locked := laser_locked_event[SceneEvent]):
            OnLocked(Locked.Aim)
        else if (laser_released_event[SceneEvent]):
            OnReleased()
        false

# レーザーに狙われる目印のタグ（FindDescendantEntitiesWithTag で探せる。目は毎フレーム探さず、下の登録簿を読む）
laser_marker_tag<public> := class(tag):

# 目印の登録簿（ラウンドごとに 1 つ）。laser_marker_component が付いたときに登録し、外れたときに外す
# 目（laser_marker_target_component）は毎フレームこれを読む（世界全体をタグで探すのは重いので、探す代わりに覚えておく）
var LaserMarkers<internal>:weak_map(session, []entity) = map{}

# 今登録されている目印の entity（並び順は登録順）
GetLaserMarkers<public>()<transacts>:[]entity =
    if (Markers := LaserMarkers[GetSession()]) then Markers else array{}

RegisterLaserMarker<internal>(Marker:entity):void =
    if (set LaserMarkers[GetSession()] = GetLaserMarkers() + array{Marker}) {}

UnregisterLaserMarker<internal>(Marker:entity):void =
    Remaining := for (Other : GetLaserMarkers(), Other <> Marker) { Other }
    if (set LaserMarkers[GetSession()] = Remaining) {}

# 役割：この entity を「レーザーに狙われる目印」にする（laser_marker_tag を付け、登録簿に登録する）
# 置き方：エディターで狙わせたい entity に付ける（実行時に付けてもよい。path_marked_cube_body_component が付ける）
laser_marker_component<public> := class<final_super>(component):

    var TagKey<private>:?tag_key = false

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        set TagKey = option{Entity.AddTag(laser_marker_tag{})}
        RegisterLaserMarker(Entity)

    OnEndSimulation<override>():void =
        UnregisterLaserMarker(Entity)

        if (Key := TagKey?, Entity.RemoveTag[Key]) {}
        set TagKey = false

        (super:)OnEndSimulation()
