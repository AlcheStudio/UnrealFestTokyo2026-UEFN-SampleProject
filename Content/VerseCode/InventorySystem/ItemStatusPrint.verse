using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }
using { ZoneSystem }

# 役割：同じ entity の item_component のイベント（拾う / 落とす / 装備 / 解除）を購読して Print する
#       アイテムが今どこにあるかを確かめるための観察用
# 置き方：エディターでアイテムの entity に付ける
# 同じ entity：item_component（公式）
item_status_print_component<public> := class<final_super>(component):

    # Print の先頭に付ける名前
    @editable:
        ToolTip := ItemStatusPrintLabelTip
        Categories := array{InventoryCategory}
    Label<public>:string = "Item"

    var Subscriptions<private>:[]cancelable = array{}

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()

        if (Item := Entity.GetComponent[item_component]):
            set Subscriptions = array:
                Item.ChangeInventoryEvent.Subscribe(OnInventoryChanged)
                Item.ChangeEquippedEvent.Subscribe(OnEquippedChanged)

    OnEndSimulation<override>():void =
        for (Subscription : Subscriptions):
            Subscription.Cancel()
        set Subscriptions = array{}

        (super:)OnEndSimulation()

    OnInventoryChanged<private>(Result:change_inventory_result):void =
        # option の中身があるかどうかで「拾った」「落とした」を見分ける
        if (Result.CurrentInventory?):
            Entity.AreaPrint("[{Label}] インベントリに入った")
        else:
            Entity.AreaPrint("[{Label}] ワールドに戻った")

    OnEquippedChanged<private>(Result:change_equipped_result):void =
        if (Result.IsItemEquipped?):
            Entity.AreaPrint("[{Label}] 装備した")
        else:
            Entity.AreaPrint("[{Label}] 装備を外した")
