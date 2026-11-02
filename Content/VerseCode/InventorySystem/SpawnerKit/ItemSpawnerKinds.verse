using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Itemization }
using { /Fortnite.com/Itemization }
using { /Fortnite.com/Weapons }
using { UtilitySystem }

# 役割：拾えるキューブのアイテムをコードで組み立てて置く
#       entity に SM_TutorialCube / item_component / fort_item_pickup_interactable_component を付けただけ
# 置き方：エディターで台座になる entity に付ける
cube_item_spawner_component<public> := class(item_spawner_component):

    # アイテムの大きさ（倍率）
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := CubeSpawnerSizeTip
        Categories := array{InventoryCategory}
    Size<public>:float = 0.4

    # アイテムの色
    @editable:
        ToolTip := CubeSpawnerColorTip
        Categories := array{InventoryCategory}
    Color<public>:color = color{R := 0.2, G := 0.6, B := 1.0}

    GetItemScale<override>()<transacts>:float = Size

    CreateItem<override>():entity =
        Item := entity{}
        Item.AddComponents(array{MakeCubeMesh(Item, Color), item_component{Entity := Item}, fort_item_pickup_interactable_component{Entity := Item}})
        Item

# 役割：アサルトライフル（レア）を置く（置く物をコードに書いた版）
# 置き方：エディターで台座になる entity に付ける
assault_rifle_spawner_component<public> := class(item_spawner_component):

    CreateItem<override>():entity =
        AssaultRifle_BR_CH4S1_Rare{}
