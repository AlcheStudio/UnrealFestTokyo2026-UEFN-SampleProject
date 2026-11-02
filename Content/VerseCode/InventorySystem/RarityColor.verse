using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Itemization }
using { UtilitySystem }

# 役割：同じ entity の rarity_component のレア度を Interval 秒ごとに Common → Legendary と切り替え、
#       そのレア度の色（rarity.Color）でキューブを塗る
#       Interval が 0 なら切り替えず、エディターで設定したレア度の色で塗るだけ
# 置き方：エディターで entity に付ける
# 同じ entity：rarity_component（公式）、SM_TutorialCube
rarity_color_component<public> := class<final_super>(component):

    # レア度を切り替える秒数（0 で切り替えない）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := RarityColorIntervalTip
        Categories := array{InventoryCategory}
    Interval<public>:float = 1.5

    OnSimulate<override>()<suspends>:void =
        if (Holder := Entity.GetComponent[rarity_component]):
            if (Interval <= 0.0):
                Entity.PaintCube(Holder.Rarity.Color)
            else:
                Order := array:
                    FortniteRarities.Common
                    FortniteRarities.Uncommon
                    FortniteRarities.Rare
                    FortniteRarities.Epic
                    FortniteRarities.Legendary

                loop:
                    for (Next : Order):
                        set Holder.Rarity = Next
                        Entity.PaintCube(Next.Color)
                        Sleep(Interval)
