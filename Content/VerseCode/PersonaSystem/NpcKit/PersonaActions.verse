using { /UnrealEngine.com/Conversations }
using { UtilitySystem }

# AI に教える「動き」（RegisterAction）の共通部分。command と guide の NPC が使う

# AI が動きを選んだときに返す形（中身は使わない。「この動きを選んだ」ことだけが大事）
npc_order<public> := struct:
    Accepted<public>:logic = true

# RegisterAction に渡す定義を作る。Name は AI が選ぶ名前、Description は「いつ使うか」の説明
MakePromptBinding<public>(Name:string, Description:string):prompt_binding_definition =
    prompt_binding_definition{Name := TextMessage(Name), Description := TextMessage(Description)}
