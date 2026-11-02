# GameLoopSystem の @editable の説明とカテゴリ（ToolTip と Categories に使う）
# Kit（StepKit / NpcKit / GrantKit / FailKit）は GameLoopSystem の中の module なので、ここの名前がそのまま見える
GameLoopCategory<public><localizes>:message = "ゲームループ"
GameLoopStepCategory<public><localizes>:message = "ゲームループの段階"
GameLoopNpcCategory<public><localizes>:message = "ゲームループの NPC"

# game_step_component
StepOrderTip<public><localizes>:message = "段階を動かす順番。小さいほど先。段階どうしで重ねない。既定 0"

# game_fail_component
FailTextTip<public><localizes>:message = "失敗したとき画面の真ん中に出す文字。既定「失敗…」"
FailShowTimeTip<public><localizes>:message = "失敗の文字を出しておく秒数。0 ですぐ終わる。既定 3"

# game_item_grant_component
ItemGrantRemoveOnEndTip<public><localizes>:message = "true：ゲームが終わったら渡した物を回収する。既定 true"

# game_hud_component
HudCenterSizeTip<public><localizes>:message = "真ん中の文字の大きさ（pt）。既定 96"
HudStatusSizeTip<public><localizes>:message = "上の状態の文字の大きさ（pt）。既定 40"

# countdown_step_component
CountdownSecondsTip<public><localizes>:message = "数え始める秒数。1 秒ずつ 1 まで数える。0 で数えない。既定 3"
CountdownGoTextTip<public><localizes>:message = "数え終わったとき 1 秒だけ出す文字。既定「GO!」"

# defeat_npc_step_component
DefeatNpcTargetCountTip<public><localizes>:message = "クリアに必要な NPC の人数。0 ですぐクリア。既定 3"
DefeatNpcIntroTextTip<public><localizes>:message = "段階の始めに真ん中へ出す文字。既定「NPCを倒せ！」"
DefeatNpcIntroTimeTip<public><localizes>:message = "始めの文字を出しておく秒数。0 で出さない。既定 2"

# exit_step_component
ExitTextTip<public><localizes>:message = "出口へ移す前に真ん中へ出す文字。既定「出口へ移動します」"
ExitDelayTip<public><localizes>:message = "文字を出してから出口へ移すまでの秒数。0 ですぐ移す。既定 1.5"

# result_step_component
ResultSuffixTip<public><localizes>:message = "クリア秒数のあとに続ける文字。既定「 秒で倒した！」"
ResultShowTimeTip<public><localizes>:message = "結果の文字を出しておく秒数。0 で見せない。既定 4"

# game_npc_behavior
NpcBehaviorChaseRadiusTip<public><localizes>:message = "挑戦者からこの距離（cm）以内にとどまる。既定 800"
NpcBehaviorThinkIntervalTip<public><localizes>:message = "NPC が状況を見直す間隔（秒）。小さいほど機敏。既定 2"

# game_npc_spawner_component
NpcSpawnerSpawnerTip<public><localizes>:message = "ゲーム中だけ有効にする NPC スポナー。開始時有効はオフにしておく"
