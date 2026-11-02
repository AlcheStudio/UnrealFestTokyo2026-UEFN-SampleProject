using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# 役割：同じ entity にある「有効 / 無効を切り替えられるコンポーネント」をまとめて点滅させる
#       種類は問わない。enableable インターフェースを持っていればメッシュもライトもインタラクトも対象になる
#       終わるとき（OnSimulate がキャンセルされたとき）は defer で全部有効に戻す
# 置き方：エディターで entity に付ける
# 同じ entity：mesh_component / light_component / interactable_component など、点滅させたいもの
enable_blink_component<public> := class<final_super>(component):

    # 有効にしておく秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := EnableBlinkOnTimeTip
        Categories := array{EnableCategory}
    OnTime<public>:float = 1.0

    # 無効にしておく秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := EnableBlinkOffTimeTip
        Categories := array{EnableCategory}
    OffTime<public>:float = 0.5

    OnSimulate<override>()<suspends>:void =
        defer:
            SetAll(true)

        loop:
            SetAll(true)
            Sleep(OnTime)
            SetAll(false)
            Sleep(OffTime)

    SetAll<private>(On:logic):void =
        # enableable[Component] が失敗する（切り替えられない）コンポーネントは for が飛ばす
        for (Component : Entity.GetComponents(), Target := enableable[Component]):
            if (On?):
                Target.Enable()
            else:
                Target.Disable()
