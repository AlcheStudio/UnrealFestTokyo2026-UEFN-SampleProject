using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { ZoneSystem }

# 役割：パスの通り道の点（A 点・B 点 …）。Order の小さい順にたどる
#       HideInGame が true なら、ゲーム中は同じ entity のメッシュを隠す（エディターで置き場所を見るためだけの目印）
# 置き方：エディターで entity に付ける
# 親：path_runner_component の entity の直下。Order は点どうしで重ねない
path_point_component<public> := class<final_super>(component):

    # たどる順番（小さいほど先）
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{100}
        ToolTip := PointOrderTip
        Categories := array{PathCategory}
    Order<public>:int = 0

    # ゲーム中は目印のメッシュを隠す
    @editable:
        ToolTip := PointHideInGameTip
        Categories := array{PathCategory}
    HideInGame<public>:logic = true

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        if (HideInGame?, Mesh := Entity.GetComponent[mesh_component]):
            set Mesh.Visible = false
            set Mesh.Collidable = false

    OnEndSimulation<override>():void =
        if (HideInGame?, Mesh := Entity.GetComponent[mesh_component]):
            set Mesh.Visible = true
            set Mesh.Collidable = true

        (super:)OnEndSimulation()

    # この点のワールドの位置
    GetPosition<public>()<transacts>:vector3 =
        Entity.GetGlobalTransform().Translation

# 役割：パスを動く本体の見た目を作る基底。何を付けるかは派生（BodyKit）が決める
# 置き方：直接は置かない（派生を置く）
# 同じ entity：path_runner_component
path_body_component<public> := class<abstract><final_super>(component):

    # 実行時に作った本体の entity に、見た目のコンポーネントと大きさを付ける
    BuildBody<public>(Body:entity):void

# 役割：本体を点から点へ運ぶ基底。どう動くかは派生（MotionKit）が決める
# 置き方：直接は置かない（派生を置く）
# 同じ entity：path_runner_component
path_motion_component<public> := class<abstract><final_super>(component):

    # Body を From から To へ動かし、着いたら戻る（向きと大きさはそのまま）
    Travel<public>(Body:entity, From:vector3, To:vector3)<suspends>:void

# Body の位置だけを Position にする（向きと大きさはそのまま）
(Body:entity).MovePathBody<internal>(Position:vector3):void =
    Current := Body.GetGlobalTransform()
    Body.SetGlobalTransform(transform{Translation := Position, Rotation := Current.Rotation, Scale := Current.Scale})

# 役割：開始時にパスを動く本体を entity ごと作って AddEntities で子に加え、子の点を Order の順に行っては戻る（A → B → A …）
#       見た目は path_body_component、動き方は path_motion_component の派生を同じ entity に付けて決める
#       終わるときは作った本体を消す
# 置き方：エディターで entity に付ける
# 同じ entity：path_body_component の派生、path_motion_component の派生（1 つずつ）
# 子：path_point_component を付けた entity（2 つ以上）
# 外から（path_guide_line_component）：FindNextPoint / FindPreviousPoint
path_runner_component<public> := class<final_super>(component):

    # 点に着いてから次へ動き出すまでの秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := RunnerWaitTimeTip
        Categories := array{PathCategory}
    WaitTime<public>:float = 0.5

    OnSimulate<override>()<suspends>:void =
        if:
            Builder := Entity.GetComponent[path_body_component]
            Motion := Entity.GetComponent[path_motion_component]
            First := FindNextPoint[false]
        then:
            Body := entity{}
            Builder.BuildBody(Body)
            Entity.AddEntities(array{Body})
            Body.MovePathBody(First.GetPosition())

            defer:
                Body.RemoveFromParent()

            var Current:path_point_component = First
            var Forward:logic = true

            loop:
                Next := if (Forward?) then option{FindNextPoint[option{Current.Order}]} else option{FindPreviousPoint[option{Current.Order}]}
                if (Target := Next?):
                    Motion.Travel(Body, Current.GetPosition(), Target.GetPosition())
                    set Current = Target
                else:
                    set Forward = logic{not Forward?}
                Sleep(WaitTime)
        else:
            Entity.AreaPrint("[path_runner] 見た目・動き方のコンポーネントと、子の点が必要です")

    # After より大きい Order で一番小さい点（After が false なら一番小さい点）。無ければ失敗する
    FindNextPoint<internal>(After:?int)<decides><transacts>:path_point_component =
        var Best:?path_point_component = false

        for (Child : Entity.GetEntities(), Point := Child.GetComponent[path_point_component]):
            if (Previous := After?, Point.Order <= Previous):
            else if (Current := Best?, Current.Order <= Point.Order):
            else:
                set Best = option{Point}

        Best?

    # Before より小さい Order で一番大きい点（Before が false なら一番大きい点）。無ければ失敗する
    FindPreviousPoint<internal>(Before:?int)<decides><transacts>:path_point_component =
        var Best:?path_point_component = false

        for (Child : Entity.GetEntities(), Point := Child.GetComponent[path_point_component]):
            if (Next := Before?, Point.Order >= Next):
            else if (Current := Best?, Current.Order >= Point.Order):
            else:
                set Best = option{Point}

        Best?
