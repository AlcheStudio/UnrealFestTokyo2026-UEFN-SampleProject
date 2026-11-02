using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /UnrealEngine.com/Temporary }
using { /Fortnite.com/Characters }

# キャラクターを Position / Rotation へ移し、移せたかを返す
#   TeleportTo[] は失敗しうる関数で、not の中で呼ぶと成功しても取り消されるので、logic{} で結果だけを受け取る
(Character:fort_character).TryTeleport<public>(Position:vector3, Rotation:rotation):logic =
    logic{Character.TeleportTo[SpatialMath.FromVector3(Position), SpatialMath.FromRotation(Rotation)]}

# 重なった entity（プレイヤーのキャラクター）から fort_character を取り出す。キャラクターでなければ失敗する
(Other:entity).FindCharacter<public>()<decides><transacts>:fort_character =
    first:
        Component : Other.GetComponents()
        fort_character[Component]

# 重なった entity から player を取り出す。NPC やプロップなら失敗する
(Other:entity).FindPlayer<public>()<decides><transacts>:player =
    player[Other.FindCharacter[].GetAgent[]]

# Player を除いた map を作る（map の要素は消せないので作り直す）
(Source:[player]t where t:type).WithoutPlayer<public>(Player:player)<transacts>:[player]t =
    var Remaining:[player]t = map{}

    for (Key -> Value : Source, Key <> Player):
        if (set Remaining[Key] = Value) {}

    Remaining
