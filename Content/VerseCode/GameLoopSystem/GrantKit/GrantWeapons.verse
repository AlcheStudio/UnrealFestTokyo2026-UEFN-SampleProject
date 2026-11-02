using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Weapons }

# 役割：ゲームが始まったらアサルトライフル（レア）を渡す
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下
grant_assault_rifle_component<public> := class(game_item_grant_component):
    CreateItem<override>()<transacts>:entity =
        AssaultRifle_BR_CH4S1_Rare{}

# 役割：ゲームが始まったら剣を渡す
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下
grant_sword_component<public> := class(game_item_grant_component):
    CreateItem<override>()<transacts>:entity =
        BasicSword_Creative_V1_Common{}

# 役割：ゲームが始まったらハンマーを渡す
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下
grant_hammer_component<public> := class(game_item_grant_component):
    CreateItem<override>()<transacts>:entity =
        BasicHammer_Creative_V1_Common{}
