using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/JSON }
using { UtilitySystem }
using { ZoneSystem }

# 役割：@editable の JSON の文字列を読み、キューブの色と大きさを決める（データで見た目を変える例）
#       例：\{"r":1.0,"g":0.5,"b":0.1,"size":1.5\}。色の項目が無ければ 0.35、size が無ければ大きさはそのまま
# 置き方：エディターで entity に付ける
# 同じ entity：SM_TutorialCube
json_style_component<public> := class<final_super>(component):

    # 色と大きさを書いた JSON
    @editable:
        ToolTip := JsonStyleJsonTip
        Categories := array{JsonCategory}
    Json<public>:string = "\{\"r\":1.0,\"g\":0.5,\"b\":0.1,\"size\":1.5\}"

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()

        if (Root := Parse[Json], Fields := Root.AsObject[]):
            Entity.PaintCube(color{R := ReadNumber(Fields, "r", 0.35), G := ReadNumber(Fields, "g", 0.35), B := ReadNumber(Fields, "b", 0.35)})
            if (Size := ReadNumberOption[Fields, "size"]):
                Entity.SetUniformScale(Size)
        else:
            Entity.AreaPrint("[json_style] JSON を読めなかった：{Json}")

    # Key の数値を読む（無ければ Default）
    ReadNumber<private>(Fields:[string]value, Key:string, Default:float)<transacts>:float =
        if (Number := ReadNumberOption[Fields, Key]) then Number else Default

    ReadNumberOption<private>(Fields:[string]value, Key:string)<decides><transacts>:float =
        Field := Fields[Key]
        if (Number := Field.AsFloat[]) then Number else 1.0 * Field.AsInt[]
