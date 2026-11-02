using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { VerseAsset.UI }
using { UtilitySystem }

# 役割：紹介の看板を管理する。この component を付けた素の entity は何も描かず、看板の置き場所と文字だけを持つ
#       プレイヤーごとに WBP_TutorialInfo のウィジェット entity を子として作り、SetPresentableToPlayers でそのプレイヤーにだけ見せる
#       子の看板は tutorial_info_view_component が、そのプレイヤーの方を向かせる（縦方向の回転はしない）
#       文字と大きさは @editable なので、エディターで書き換えられる
# 置き方：エディターで素の entity に付ける（ウィジェットの entity には付けない）
# 子：WBP_TutorialInfo_entity（実行時にプレイヤーごとに作る）
tutorial_info_component<public> := class<final_super>(component):

    # 看板の見出し
    @editable:
        ToolTip := TutorialInfoTitleTip
        Categories := array{InfoCategory}
    Title<public>:string = ""

    # 看板の説明文
    @editable:
        ToolTip := TutorialInfoBodyTip
        Categories := array{InfoCategory}
    Body<public>:string = ""

    # 看板の大きさ（倍率）
    @editable_number(float):
        MinValue := option{0.05}
        MaxValue := option{10.0}
        ToolTip := TutorialInfoSizeTip
        Categories := array{InfoCategory}
    Size<public>:float = 6.0

    OnSimulate<override>()<suspends>:void =
        if (Playspace := Entity.GetPlayspaceForEntity[]):
            for (Player : Playspace.GetPlayers()):
                AddView(Player)

            loop:
                Player := Playspace.PlayerAddedEvent().Await()
                AddView(Player)

    # Player 専用の看板を子として作る（すでにあれば作らない）
    AddView<private>(Player:player):void =
        if (not HasView[Player]):
            View := WBP_TutorialInfo_entity{}
            set View.Title = TextMessage(Title)
            set View.Body = TextMessage(Body)

            Facing := tutorial_info_view_component{Entity := View, Player := Player, Size := Size}
            View.AddComponents(array{Facing})

            # 子にする前に見せる相手を絞る（1 フレームだけ全員に見えるのを防ぐ）
            View.SetPresentableToPlayers(option{array{Player}})
            Entity.AddEntities(array{View})

    HasView<private>(Player:player)<decides><transacts>:void =
        Found := for (Child : Entity.GetEntities(), View := Child.GetComponent[tutorial_info_view_component], View.Player = Player):
            View

        Found.Length > 0

# 役割：プレイヤー専用の子の看板を、毎フレーム（TickEvents.PrePhysics）そのプレイヤーの方へ水平に向ける。プレイヤーが抜けたら看板ごと消える
#       位置は親の entity、大きさは Size、向きだけを変える
# 置き方：実行時に tutorial_info_component が作る（エディターでは置かない）
tutorial_info_view_component<internal> := class<final_super>(component):

    # この看板を見せるプレイヤー
    Player<internal>:player

    # 看板の大きさ（倍率）
    Size<internal>:float = 1.0

    OnSimulate<override>()<suspends>:void =
        race:
            loop:
                Face()
                TickEvents.PrePhysics.Await()
            block:
                if (Playspace := Entity.GetPlayspaceForEntity[]):
                    loop:
                        Removed := Playspace.PlayerRemovedEvent().Await()
                        if (Removed = Player):
                            break
                else:
                    Sleep(Inf)

        Entity.RemoveFromParent()

    Face<private>():void =
        if:
            Parent := Entity.GetParent[]
            Body := Player.GetFortCharacter[].GetEntity[]
        then:
            Base := Parent.GetGlobalTransform().Translation
            Offset := Body.GetGlobalTransform().Translation - Base

            # 縦方向を捨てて水平の向きだけにする
            FlatLength := Sqrt(Offset.Forward * Offset.Forward + Offset.Left * Offset.Left)

            if (FlatLength > 1.0):
                Toward := vector3{Forward := Offset.Forward / FlatLength, Left := Offset.Left / FlatLength, Up := 0.0}
                Entity.SetGlobalTransform(transform:
                    Translation := Base
                    Rotation := MakeShortestRotationBetween(vector3{Forward := 1.0}, Toward)
                    Scale := vector3{Forward := Size, Left := Size, Up := Size}
                )
