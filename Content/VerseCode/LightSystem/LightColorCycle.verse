using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }

# 役割：同じ entity のライトの色を、FirstColor → SecondColor → ThirdColor の順に Interval 秒ごとに切り替える
#       基底クラス light_component の ColorFilter だけを使うので、球 / スポット / 矩形 / カプセルのどのライトでも動く
# 置き方：エディターで entity に付ける
# 同じ entity：sphere_light_component / spot_light_component などの light_component（公式）
light_color_cycle_component<public> := class<final_super>(component):

    # 1 番目の色
    @editable:
        ToolTip := ColorCycleFirstColorTip
        Categories := array{LightCategory}
    FirstColor<public>:color = color{R := 1.0, G := 0.1, B := 0.1}

    # 2 番目の色
    @editable:
        ToolTip := ColorCycleSecondColorTip
        Categories := array{LightCategory}
    SecondColor<public>:color = color{R := 0.1, G := 1.0, B := 0.2}

    # 3 番目の色
    @editable:
        ToolTip := ColorCycleThirdColorTip
        Categories := array{LightCategory}
    ThirdColor<public>:color = color{R := 0.1, G := 0.4, B := 1.0}

    # 1 色あたりの秒数
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{60.0}
        ToolTip := ColorCycleIntervalTip
        Categories := array{LightCategory}
    Interval<public>:float = 1.0

    OnSimulate<override>()<suspends>:void =
        if (Light := Entity.GetComponent[light_component]):
            loop:
                set Light.ColorFilter = FirstColor
                Sleep(Interval)
                set Light.ColorFilter = SecondColor
                Sleep(Interval)
                set Light.ColorFilter = ThirdColor
                Sleep(Interval)
