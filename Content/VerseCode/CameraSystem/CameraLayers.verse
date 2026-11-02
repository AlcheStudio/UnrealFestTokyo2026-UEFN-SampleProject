using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { UtilitySystem }

# 役割：カメラの描画位置を、component が毎フレーム入れる Offset のぶんだけ上下にずらす
#       Evaluate は <reads> なので時間を取れない。Offset は camera_layer_bob_component が OnSimulate で更新する
#       元の camera_state は CloneCameraState でコピーし、RenderLocation だけ差し替える
#       （archetype では「先に書いたフィールド → コンストラクター」の順。先に書いたフィールドはコピーで上書きされない）
camera_bob_modifier<public> := class(camera_modifier):

    # 今フレームの上下のずれ（cm）。camera_layer_bob_component が毎フレーム書く
    var Offset<internal>:float = 0.0

    Evaluate<override>(InValue:camera_state)<reads>:camera_state =
        camera_state:
            RenderLocation := InValue.RenderLocation + vector3{Left := 0.0, Up := Offset, Forward := 0.0}
            CloneCameraState<constructor>(InValue)

# 役割：ゾーンに入ったプレイヤーの camera_director_component の層に camera_bob_modifier を積む（抽象・直接は付けない）
#       どの層に積むかは派生で決める。プレイヤーの director が持つ層は 3 つ
#         Pre：どのカメラが選ばれるより前に走る（カメラ全体で共通の初期値を入れる）
#         Post：カメラが決まり、ブレンドまで終わった結果に走る（当たり判定や反動など、1 回だけ走らせたいもの）
#         Presentation：見た目だけの仕上げ（揺れなど。照準や移動方向には影響させない）
#       （カメラそのものではなく、プレイヤー側の director の層に積むのが camera_follow_component との違い）
#       入ったプレイヤーごとに cancelable を覚え、出たら / 終了時に Cancel で外す
# 置き方：エディターで派生を 1 つ、camera_zone_component の子 entity（カメラを付けた entity）に付ける
# 同じ entity：camera_component（なくても動く。director の層に積むため）
camera_layer_bob_component<public> := class<abstract><final_super>(component):

    # 上下に揺れる幅（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := LayerBobAmplitudeTip
        Categories := array{CameraCategory}
    Amplitude<public>:float = 10.0

    # 1 往復にかける秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := LayerBobPeriodTip
        Categories := array{CameraCategory}
    Period<public>:float = 1.0

    # 全プレイヤーで共有するモディファイアー（Offset を毎フレーム更新する）
    Bob<private>:camera_bob_modifier = camera_bob_modifier{}

    # プレイヤーごとに、積んだモディファイアーを外すための cancelable
    var Added<private>:[player]cancelable = map{}

    OnSimulate<override>()<suspends>:void =
        loop:
            Phase := GetSimulationElapsedTime() * 2.0 * PiFloat / Max(Period, 0.1)
            set Bob.Offset = Amplitude * Sin(Phase)

            TickEvents.PrePhysics.Await()

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Changed := camera_target_event[SceneEvent], Player := player[Changed.Agent]):
            Remove(Player)

            if:
                Changed.Entered?
                Director := Player.FindCameraDirector[]
            then:
                Stack := StackFor(Director)
                Handle := Stack.AddModifier(Bob, Stack.LastPosition)
                Stored := option{set Added[Player] = Handle}
        false

    OnEndSimulation<override>():void =
        for (Player -> Handle : Added):
            Handle.Cancel()
        set Added = map{}

        (super:)OnEndSimulation()

    # 積む先の層（派生で決める）
    StackFor<protected>(Director:camera_director_component)<transacts>:modifier_stack(camera_state)

    Remove<private>(Player:player):void =
        if (Handle := Added[Player]):
            Handle.Cancel()
            set Added = Added.WithoutPlayer(Player)

# カメラが選ばれる前の層（Pre）に積む
camera_pre_bob_component<public> := class(camera_layer_bob_component):
    StackFor<override>(Director:camera_director_component)<transacts>:modifier_stack(camera_state) = Director.PreCameraModifiers

# ブレンド後の結果の層（Post）に積む
camera_post_bob_component<public> := class(camera_layer_bob_component):
    StackFor<override>(Director:camera_director_component)<transacts>:modifier_stack(camera_state) = Director.PostCameraModifiers

# 見た目だけの層（Presentation）に積む
camera_presentation_bob_component<public> := class(camera_layer_bob_component):
    StackFor<override>(Director:camera_director_component)<transacts>:modifier_stack(camera_state) = Director.PresentationCameraModifiers

# 役割：同じ entity の perspective_camera_component の画角を、度で指定して入れる
#       FieldOfView はラジアンなので DegreesToRadians で直す
# 置き方：エディターで camera_zone_component の子 entity（カメラを付けた entity）に付ける
# 同じ entity：perspective_camera_component
camera_fov_component<public> := class<final_super>(component):

    # 水平の画角（度）
    @editable_number(float):
        MinValue := option{1.0}
        MaxValue := option{179.0}
        ToolTip := FovDegreesTip
        Categories := array{CameraCategory}
    FovDegrees<public>:float = 90.0

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (Camera := Entity.GetComponent[perspective_camera_component]):
            set Camera.FieldOfView = DegreesToRadians(FovDegrees)
