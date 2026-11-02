using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Itemization }
using { /Fortnite.com/Itemization }
using { ZoneSystem }

# プレイヤー（agent も entity）の子孫から、武器を入れるホットバーのインベントリを探す
(Agent:agent).FindWeaponHotbar<internal>()<decides><transacts>:inventory_component =
    first:
        Hotbar : Agent.FindDescendantComponents(fort_inventory_weapon_hotbar_component)
        Hotbar

# 役割：ゲームが始まった瞬間（game_started_event）に、挑戦者の武器ホットバーへアイテムを 1 つ入れる基底
#       何を渡すかは派生（GrantKit）の CreateItem が決める。渡す物を変えるときは別の派生を付ける
#       RemoveOnEnd が true なら、ゲームが終わったとき（game_ended_event）に渡した物を回収する
#       回収できるよう、既にあるスタックとはまとめない（AllowMergeItems := false）
# 置き方：直接は置かない（派生を置く）。1 entity に 1 つまで。複数渡すときは entity を分けて並べる
# 親：game_loop_component の entity の直下
game_item_grant_component<public> := class<abstract><final_super>(component):

    # true：ゲームが終わったら渡した物を回収する
    @editable:
        ToolTip := ItemGrantRemoveOnEndTip
        Categories := array{GameLoopCategory}
    RemoveOnEnd<public>:logic = true

    var Granted<private>:?entity = false

    # 渡すアイテムの entity を作る
    CreateItem<protected>()<transacts>:entity

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Started := game_started_event[SceneEvent]):
            Grant(Started.Agent)
        else if (game_ended_event[SceneEvent], RemoveOnEnd?):
            Revoke()
        false

    Grant<private>(Agent:agent):void =
        if (Hotbar := Agent.FindWeaponHotbar[]):
            Item := CreateItem()
            Result := Hotbar.AddItem(Item, ?AllowMergeItems := false)

            if (Result.GetSuccess[]):
                set Granted = option{Item}
            else:
                Entity.AreaPrint("[game_item_grant] ホットバーに入らなかった")
        else:
            Entity.AreaPrint("[game_item_grant] 挑戦者の武器ホットバーが見つからない")

    Revoke<private>():void =
        if (Item := Granted?, Holder := Item.GetComponent[item_component], Inventory := Holder.GetParentInventory[]):
            Inventory.RemoveItem(Item)

        set Granted = false
