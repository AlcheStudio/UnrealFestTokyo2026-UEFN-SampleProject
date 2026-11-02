using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }

# 役割：AI の NPC が話している文章を、近くにいるプレイヤーの画面の下中央に字幕として出す（半透明の黒い帯の上に白い文字）
#       文章は NPC の振る舞い（persona_npc_behavior）が CommitSayEvent で受け取って渡してくる。話し終わると消す
#       付けなければ字幕は出ない（付け外しで選ぶ）
# 置き方：エディターで台座の entity に付ける
# 同じ entity：persona_npc_component の派生
persona_subtitle_component<public> := class<final_super>(component):

    # 文字の大きさ
    @editable_number(float):
        MinValue := option{1.0}
        MaxValue := option{200.0}
        ToolTip := PersonaSubtitleTextSizeTip
        Categories := array{PersonaCategory}
    TextSize<public>:float = 28.0

    # 字幕の横幅（px）。超える文章は折り返す
    @editable_number(float):
        MinValue := option{200.0}
        MaxValue := option{1900.0}
        ToolTip := PersonaSubtitleMaxWidthTip
        Categories := array{PersonaCategory}
    MaxWidth<public>:float = 1100.0

    # 画面の下端からの余白（px）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1000.0}
        ToolTip := PersonaSubtitleMarginTip
        Categories := array{PersonaCategory}
    Margin<public>:float = 160.0

    # 背景（黒）の濃さ
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{1.0}
        ToolTip := PersonaSubtitleBackgroundOpacityTip
        Categories := array{PersonaCategory}
    BackgroundOpacity<public>:float = 0.6

    # 文字の色
    @editable:
        ToolTip := PersonaSubtitleTextColorTip
        Categories := array{PersonaCategory}
    TextColor<public>:color = color{R := 1.0, G := 1.0, B := 1.0}

    # 帯の中の文字の余白（px）
    TextPadding<private>:float = 16.0

    # プレイヤーごとの画面の部品
    var Roots<private>:[player]canvas = map{}
    var Boxes<private>:[player]overlay = map{}
    var Labels<private>:[player]text_block = map{}

    OnEndSimulation<override>():void =
        for (Player -> Root : Roots, PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(Root)

        set Roots = map{}
        set Boxes = map{}
        set Labels = map{}

        (super:)OnEndSimulation()

    # Player の画面に Text を出す（部品があれば書き換えて見せ、無ければ作って下中央に置く）
    Show<internal>(Player:player, Text:message):void =
        if (Label := Labels[Player], Box := Boxes[Player]):
            Label.SetText(Text)
            Box.SetVisibility(widget_visibility.Visible)
        else if (PlayerUI := GetPlayerUI[Player]):
            Label := MakeLabel()
            Box := MakeBox(Label)
            Root := canvas{}

            Root.AddWidget(MakeBottomCenterSlot(Box))
            PlayerUI.AddWidget(Root)

            Label.SetText(Text)
            if (set Roots[Player] = Root, set Boxes[Player] = Box, set Labels[Player] = Label) {}

    # Player の画面の字幕を消す（部品は残し、次に話すときにまた見せる）
    Hide<internal>(Player:player):void =
        if (Box := Boxes[Player]):
            Box.SetVisibility(widget_visibility.Collapsed)

    # 中央そろえで折り返す文字
    MakeLabel<private>():text_block =
        Label := text_block{DefaultTextColor := TextColor, DefaultTextSize := TextSize, DefaultJustification := text_justification.Center}
        set Label.AutoWrap = true
        set Label.WrapWidth = MaxWidth - TextPadding * 2.0
        Label

    # 半透明の黒い帯（横幅 MaxWidth）の上に文字を重ねる。帯の高さは文字に合わせて伸びる
    MakeBox<private>(Label:text_block):overlay =
        # 濃さは 0〜1 の型で渡す（@editable は float なので、範囲内か確かめてから使う）
        Opacity := if (Clamped := type{_X:float where 0.0 <= _X, _X <= 1.0}[BackgroundOpacity]) then Clamped else 1.0
        Background := color_block{DefaultColor := NamedColors.Black, DefaultOpacity := Opacity, DefaultDesiredSize := vector2{X := MaxWidth, Y := 0.0}}
        overlay:
            Slots := array:
                overlay_slot{Widget := Background, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill}
                overlay_slot{Widget := Label, HorizontalAlignment := horizontal_alignment.Center, VerticalAlignment := vertical_alignment.Center, Padding := margin{Left := TextPadding, Top := TextPadding * 0.5, Right := TextPadding, Bottom := TextPadding * 0.5}}

    # 下端の中央を基準に、余白ぶん上へ寄せて置く
    MakeBottomCenterSlot<private>(Widget:widget):canvas_slot =
        canvas_slot:
            Anchors := anchors{Minimum := vector2{X := 0.5, Y := 1.0}, Maximum := vector2{X := 0.5, Y := 1.0}}
            Alignment := vector2{X := 0.5, Y := 1.0}
            Offsets := margin{Top := -Margin}
            SizeToContent := true
            Widget := Widget
