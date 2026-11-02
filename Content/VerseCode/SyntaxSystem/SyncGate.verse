using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { UtilitySystem }
using { ZoneSystem }

# 役割：子 entity のキューブ 2 つ（床スイッチ）の両方に誰かが入ったら、自分のキューブをグリーンにする
#       2 つの待ちを sync で同時に進め、両方終わったら次へ進む（どちらが先でもよい）
#       床スイッチは「子 entity のうち volume_detector_component を持つもの」を for の失敗フィルターで集める
#       床スイッチの detector が SendUp する volume_entered_event を OnReceive で受け、Volume が子 entity なら PadEnteredEvent を Signal する
#       OnSimulate はそれを待ち、Volume が PadA か PadB かで振り分ける
# 置き方：エディターで entity に付け、子 entity を 2 つ作ってそれぞれに SM_TutorialVolumeCube（OverlapAll）と volume_detector_component を付ける
# 同じ entity：SM_TutorialCube か SM_TutorialVolumeCube（ゲート）
# 子：床スイッチ 2 つ（SM_TutorialVolumeCube、volume_detector_component）
sync_gate_component<public> := class<final_super>(component):

    # 開いた状態を見せる秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := SyncPadOpenTimeTip
        Categories := array{SyntaxCategory}
    OpenTime<public>:float = 3.0

    # 床スイッチ（子 entity のボリューム）に誰かが入った。中身は入られた床スイッチの entity
    PadEnteredEvent<private>:event(entity) = event(entity){}

    # 子 entity のボリュームの知らせだけを Signal に変える（OnReceive では待てないので、待つのは OnSimulate）。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := volume_entered_event[SceneEvent], Parent := Entered.Volume.GetParent[], Parent = Entity):
            PadEnteredEvent.Signal(Entered.Volume)
        false

    OnSimulate<override>()<suspends>:void =
        # 子 entity のうち、GetComponent に成功したものだけが対象になる
        Pads := for (Child : Entity.GetEntities(), Child.GetComponent[volume_detector_component]):
            Child

        if (PadA := Pads[0], PadB := Pads[1]):
            loop:
                Entity.PaintCube(SyntaxIdleColor)
                PadA.PaintCube(SyntaxWaitColor)
                PadB.PaintCube(SyntaxWaitColor)

                sync:
                    block:
                        WaitPad(PadA)
                        PadA.PaintCube(SyntaxSuccessColor)
                    block:
                        WaitPad(PadB)
                        PadB.PaintCube(SyntaxSuccessColor)

                Entity.PaintCube(SyntaxSuccessColor)
                Entity.AreaPrint("[sync_gate] 両方そろった")
                Sleep(OpenTime)
        else:
            Entity.AreaPrint("[sync_gate] 子 entity 2 つに volume_detector_component が必要です")

    # Pad の床スイッチに誰かが入るまで待つ（もう片方の床スイッチの知らせは見送る）
    WaitPad<private>(Pad:entity)<suspends>:void =
        loop:
            Volume := PadEnteredEvent.Await()
            if (Volume = Pad):
                break
