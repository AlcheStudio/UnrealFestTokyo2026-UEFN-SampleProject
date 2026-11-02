using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }
using { UtilitySystem }

# 役割：子孫のエリアから SendUp で届く area_entered_event / area_exited_event を受けて、
#       そのプレイヤーの画面の右中央に「今いるエリアの名前」を出す（説明は出さない）
#       文字はプレイヤーごとに 1 つ。エリアを出たら消す。出入りの順が入れ替わっても、今いるエリアの名前だけが残る
# 置き方：エディターで、エリアの床をすべて子に持つ entity に付ける（床は子にしないと SendUp が届かない）
# 子：area_label_component と volume_detector_component を付けた床の entity
area_name_hud_component<public> := class<final_super>(component):

    # 文字の大きさ
    @editable_number(float):
        MinValue := option{1.0}
        MaxValue := option{300.0}
        ToolTip := AreaNameHudTextSizeTip
        Categories := array{LayoutCategory}
    TextSize<public>:float = 36.0

    # 画面の右端からの余白（px）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := AreaNameHudMarginTip
        Categories := array{LayoutCategory}
    Margin<public>:float = 48.0

    # 文字の色
    @editable:
        ToolTip := AreaNameHudTextColorTip
        Categories := array{LayoutCategory}
    TextColor<public>:color = color{R := 0.55, G := 0.9, B := 1.0}

    # プレイヤーごとの画面の部品と、今いるエリアの名前
    var Roots<private>:[player]canvas = map{}
    var Labels<private>:[player]text_block = map{}
    var Current<private>:[player]string = map{}

    # 子孫のエリアからの出入りを受けて文字を変える。消費しない
    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Entered := area_entered_event[SceneEvent]):
            ShowName(Entered.Player, Entered.AreaName)
        else if (Exited := area_exited_event[SceneEvent]):
            # 隣のエリアに先に入っていたら（出入りの順が入れ替わったら）、その名前は消さない
            if (Current[Exited.Player] = Exited.AreaName):
                ClearName(Exited.Player)
        false

    OnEndSimulation<override>():void =
        for (Player -> Root : Roots, PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(Root)

        set Roots = map{}
        set Labels = map{}
        set Current = map{}

        (super:)OnEndSimulation()

    # 文字があれば書き換え、無ければ作って右中央に置く（画面への追加は取り消せない処理なので、if の条件の外で行う）
    ShowName<private>(Player:player, AreaName:string):void =
        if (Label := Labels[Player]):
            Label.SetText(TextMessage(AreaName))
        else if (PlayerUI := GetPlayerUI[Player]):
            Label := text_block{DefaultTextColor := TextColor, DefaultTextSize := TextSize, DefaultShadowOpacity := 0.8}
            Root := canvas{}

            Root.AddWidget(MakeRightCenterSlot(Label))
            PlayerUI.AddWidget(Root)

            Label.SetText(TextMessage(AreaName))
            if (set Roots[Player] = Root, set Labels[Player] = Label) {}

        if (set Current[Player] = AreaName) {}

    ClearName<private>(Player:player):void =
        if (Label := Labels[Player]):
            Label.SetText(TextMessage(""))
        if (set Current[Player] = "") {}

    # 右端の高さ半分を基準に、余白ぶん内側へ寄せて置く（文字の大きさはそのまま）
    MakeRightCenterSlot<private>(Widget:widget):canvas_slot =
        canvas_slot:
            Anchors := anchors{Minimum := vector2{X := 1.0, Y := 0.5}, Maximum := vector2{X := 1.0, Y := 0.5}}
            Alignment := vector2{X := 1.0, Y := 0.5}
            Offsets := margin{Left := -Margin}
            SizeToContent := true
            Widget := Widget
