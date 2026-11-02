using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { UtilitySystem }

# 役割：同じ entity の sphere_light_component の色と明るさを、Period 秒周期で A と B のあいだを行き来させる（毎フレーム TickEvents.PrePhysics で書く）
# 置き方：エディターで entity に付ける
# 同じ entity：sphere_light_component（公式。明るさはカンデラ、範囲は cm）
light_pulse_component<public> := class<final_super>(component):

    # 暗いときの色
    @editable:
        ToolTip := PulseColorATip
        Categories := array{LightCategory}
    ColorA<public>:color = color{R := 0.1, G := 0.7, B := 1.0}

    # 明るいときの色
    @editable:
        ToolTip := PulseColorBTip
        Categories := array{LightCategory}
    ColorB<public>:color = color{R := 1.0, G := 0.2, B := 0.8}

    # 暗いときの明るさ（カンデラ）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{100000.0}
        ToolTip := PulseMinIntensityTip
        Categories := array{LightCategory}
    MinIntensity<public>:float = 30.0

    # 明るいときの明るさ（カンデラ）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{100000.0}
        ToolTip := PulseMaxIntensityTip
        Categories := array{LightCategory}
    MaxIntensity<public>:float = 600.0

    # 光が届く範囲（cm）
    @editable_number(float):
        MinValue := option{0.0}
        MaxValue := option{20000.0}
        ToolTip := PulseRadiusTip
        Categories := array{LightCategory}
    Radius<public>:float = 1000.0

    # 1 往復にかける秒数
    @editable_number(float):
        MinValue := option{0.1}
        MaxValue := option{60.0}
        ToolTip := PulsePeriodTip
        Categories := array{LightCategory}
    Period<public>:float = 2.0

    OnSimulate<override>()<suspends>:void =
        if (Light := Entity.GetComponent[sphere_light_component]):
            set Light.AttenuationRadius = option{Radius}

            loop:
                Phase := GetSimulationElapsedTime() * 2.0 * PiFloat / Max(Period, 0.1)
                Ratio := 0.5 + 0.5 * Sin(Phase)

                set Light.ColorFilter = LerpColor(ColorA, ColorB, Ratio)
                set Light.Intensity = Lerp(MinIntensity, MaxIntensity, Ratio)

                TickEvents.PrePhysics.Await()
