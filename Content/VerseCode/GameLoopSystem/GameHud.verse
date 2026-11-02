using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }
using { UtilitySystem }

# 役割：ゲーム中、挑戦者の画面に「真ん中の文字」と「上の状態の文字」を出す
#       game_started_event で出し、game_ended_event で消す。文字は game_center_text_event / game_status_text_event で変わる
#       配列を使わないよう、canvas へは AddWidget で 1 つずつ足す
# 置き方：エディターで entity に付ける
# 親：game_loop_component の entity の直下
game_hud_component<public> := class<final_super>(component):

    # 真ん中の文字の大きさ
    @editable_number(float):
        MinValue := option{1.0}
        MaxValue := option{300.0}
        ToolTip := HudCenterSizeTip
        Categories := array{GameLoopCategory}
    CenterSize<public>:float = 96.0

    # 上の文字の大きさ
    @editable_number(float):
        MinValue := option{1.0}
        MaxValue := option{300.0}
        ToolTip := HudStatusSizeTip
        Categories := array{GameLoopCategory}
    StatusSize<public>:float = 40.0

    var ShownUI<private>:?player_ui = false
    var ShownRoot<private>:?canvas = false
    var CenterText<private>:?text_block = false
    var StatusText<private>:?text_block = false

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (Started := game_started_event[SceneEvent]):
            Show(Started.Agent)
        else if (game_ended_event[SceneEvent]):
            Hide()
        else if (Center := game_center_text_event[SceneEvent], Text := CenterText?):
            Text.SetText(TextMessage(Center.Text))
        else if (Status := game_status_text_event[SceneEvent], Text := StatusText?):
            Text.SetText(TextMessage(Status.Text))
        false

    OnEndSimulation<override>():void =
        Hide()
        (super:)OnEndSimulation()

    Show<private>(Agent:agent):void =
        Hide()

        if (Player := player[Agent], PlayerUI := GetPlayerUI[Player]):
            Center := text_block{DefaultTextColor := NamedColors.White, DefaultTextSize := CenterSize}
            Status := text_block{DefaultTextColor := NamedColors.White, DefaultTextSize := StatusSize}
            Root := canvas{}

            Root.AddWidget(MakeSlot(Center, 0.5, 0.4))
            Root.AddWidget(MakeSlot(Status, 0.5, 0.12))
            PlayerUI.AddWidget(Root)

            set ShownUI = option{PlayerUI}
            set ShownRoot = option{Root}
            set CenterText = option{Center}
            set StatusText = option{Status}

    Hide<private>():void =
        if (PlayerUI := ShownUI?, Root := ShownRoot?):
            PlayerUI.RemoveWidget(Root)

        set ShownUI = false
        set ShownRoot = false
        set CenterText = false
        set StatusText = false

    # 画面の (X, Y) の割合の位置に、文字の大きさのまま置く
    MakeSlot<private>(Widget:widget, X:float, Y:float):canvas_slot =
        canvas_slot:
            Anchors := anchors{Minimum := vector2{X := X, Y := Y}, Maximum := vector2{X := X, Y := Y}}
            Alignment := vector2{X := 0.5, Y := 0.5}
            SizeToContent := true
            Widget := Widget
