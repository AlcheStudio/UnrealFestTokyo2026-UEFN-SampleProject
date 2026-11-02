using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Verse.org/Colors }
using { UtilitySystem }
using { MotionSystem }

# 役割：開始時に Count 個のキューブを entity ごとコードで組み立てて子に加え、自分のまわりを回らせる
#       各キューブには SM_TutorialCube / orbit_component、BobHeight > 0 なら bob_component も付ける
#       （エディターで付けていたコンポーネントを、Verse から AddComponents で付けている）
#       終わるときは作った entity を RemoveFromParent で片付ける
# 置き方：エディターで entity に付ける（この entity が輪の中心になる。動かすと輪ごと付いてくる）
build_ring_component<public> := class<final_super>(component):

    # 作るキューブの数
    @editable_number(int):
        MinValue := option{0}
        MaxValue := option{100}
        ToolTip := BuildRingCountTip
        Categories := array{BuildCategory}
    Count<public>:int = 6

    # 輪の半径（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10000.0}
        ToolTip := BuildRingRadiusTip
        Categories := array{BuildCategory}
    Radius<public>:float = 250.0

    # 回る速さ（度 / 秒）
    @editable_number(float):
        MinValue := option{-720.0}
        MaxValue := option{720.0}
        ToolTip := BuildRingSpeedTip
        Categories := array{BuildCategory}
    Speed<public>:float = 45.0

    # キューブの大きさ（倍率）
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := BuildRingSizeTip
        Categories := array{BuildCategory}
    Size<public>:float = 0.4

    # 上下に揺らす幅（cm。0 なら bob_component を付けない）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := BuildRingBobHeightTip
        Categories := array{BuildCategory}
    BobHeight<public>:float = 40.0

    # キューブの色
    @editable:
        ToolTip := BuildRingColorTip
        Categories := array{BuildCategory}
    Color<public>:color = color{R := 1.0, G := 0.6, B := 0.1}

    var Built<private>:[]entity = array{}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Build()

    OnEndSimulation<override>():void =
        for (Child : Built):
            Child.RemoveFromParent()
        set Built = array{}

        (super:)OnEndSimulation()

    Build<private>():void =
        Step := 360.0 / Max(1.0 * Count, 1.0)
        Phases := MakePhases(Step)

        for (Phase : Phases):
            Child := entity{}
            Mesh := MakeCubeMesh(Child, Color)
            Orbit := orbit_component{Entity := Child, Radius := Radius, Speed := Speed, Phase := Phase}
            # 条件で付けるコンポーネントを変える（if は式なので配列をそのまま返せる）
            Extra:[]component = if (BobHeight > 0.0) then array{bob_component{Entity := Child, Height := BobHeight, Phase := Phase * 2.0}} else array{}

            Child.AddComponents(array{Mesh, Orbit} + Extra)
            Child.SetUniformScale(Size)
            Entity.AddEntities(array{Child})
            set Built += array{Child}

    # Count 個ぶんの開始角度（0, Step, Step*2, ...）を配列で作る
    MakePhases<private>(Step:float):[]float =
        var Phases:[]float = array{}
        var Phase:float = 0.0

        for (Index := 1..Count):
            set Phases += array{Phase}
            set Phase += Step

        Phases
