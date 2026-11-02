using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /UnrealEngine.com/Itemization }
using { ZoneSystem }

# 役割：台座の上に拾えるアイテムを置き、拾われたら RespawnTime 秒後にまた置く基底
#       何を置くかは派生の CreateItem が決める（置くものを変えるときは別の派生を付ける）
#       アイテムは item_component.Drop でワールドに出す。Drop できないときは台座の子として置く
# 置き方：直接は置かない（派生を置く）。台座になる entity に付ける
item_spawner_component<public> := class<abstract><final_super>(component):

    # 拾われてから次を置くまでの秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := ItemSpawnerRespawnTimeTip
        Categories := array{InventoryCategory}
    RespawnTime<public>:float = 3.0

    # 台座からの高さ（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{10000.0}
        ToolTip := ItemSpawnerHeightTip
        Categories := array{InventoryCategory}
    Height<public>:float = 120.0

    # 置くアイテムの entity を作る（item_component を持つこと）
    CreateItem<protected>():entity

    # 置くアイテムの大きさ（倍率）
    GetItemScale<protected>()<transacts>:float = 1.0

    OnSimulate<override>()<suspends>:void =
        loop:
            Spawned := SpawnItem()
            if (Item := Spawned?):
                # インベントリに入る（拾われる）まで待つ
                loop:
                    Changed := Item.ChangeInventoryEvent.Await()
                    if (Changed.CurrentInventory?):
                        break
            else:
                Entity.AreaPrint("[item_spawner] item_component を持つアイテムを作れなかった")

            Sleep(RespawnTime)

    # アイテムを作って置く。AddEntities などは取り消せない処理なので、失敗コンテキストの外で呼ぶ
    SpawnItem<private>():?item_component =
        ItemEntity := CreateItem()
        if (Holder := ItemEntity.GetComponent[item_component]):
            Base := Entity.GetGlobalTransform()
            Size := GetItemScale()
            Placement := transform:
                Translation := Base.Translation + vector3{Up := Height}
                Rotation := IdentityRotation()
                Scale := vector3{Forward := Size, Left := Size, Up := Size}

            Dropped := logic{Holder.Drop[Placement]}
            if (not Dropped?):
                Entity.AddEntities(array{ItemEntity})
                ItemEntity.SetGlobalTransform(Placement)

            option{Holder}
        else:
            false
