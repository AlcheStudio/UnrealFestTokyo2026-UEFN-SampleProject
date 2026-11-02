using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /UnrealEngine.com/Itemization }
using { ZoneSystem }

# 役割：拾われてから ReturnTime 秒たつと、インベントリから出して最初に置いてあった場所へ戻す（ブーメランのようなアイテム）
#       「時間がたつ」と「その前にプレイヤーが自分で落とす」を race で競わせる
# 置き方：エディターでアイテムの entity に付ける
# 同じ entity：item_component / fort_item_pickup_interactable_component（公式）
item_return_component<public> := class<final_super>(component):

    # 拾われてから戻るまでの秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := ItemReturnReturnTimeTip
        Categories := array{InventoryCategory}
    ReturnTime<public>:float = 5.0

    # 最初に置いてあった場所。拾われて親が変わると OnSimulate がやり直されることがあるので、一度だけ覚える
    var HomeTransform<private>:?transform = false

    OnSimulate<override>()<suspends>:void =
        if (not HomeTransform?):
            set HomeTransform = option{Entity.GetGlobalTransform()}

        if (Item := Entity.GetComponent[item_component], Home := HomeTransform?):
            loop:
                # インベントリに入るまで待つ
                loop:
                    Changed := Item.ChangeInventoryEvent.Await()
                    if (Changed.CurrentInventory?):
                        break

                # 時間切れなら強制的に戻す。先にワールドへ落とされたら何もしない
                TimedOut := race:
                    block:
                        Sleep(ReturnTime)
                        true
                    block:
                        loop:
                            Changed := Item.ChangeInventoryEvent.Await()
                            if (not Changed.CurrentInventory?):
                                break
                        false

                if (TimedOut?, Item.Drop[Home]):
                    Entity.AreaPrint("[item_return] 元の場所に戻った")
