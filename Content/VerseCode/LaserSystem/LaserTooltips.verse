# LaserSystem の @editable の説明とカテゴリ（ToolTip と Categories に使う）
# Kit（TargetKit / ReactionKit）は LaserSystem の中の module なので、ここの名前がそのまま見える
LaserCategory<public><localizes>:message = "レーザー"

# laser_eye_component
EyeWidthTip<public><localizes>:message = "レーザーの太さ（cm）。既定 6"

# laser_color_reaction_component
ColorReactionTargetColorTip<public><localizes>:message = "相手を狙っているときの色。1 より大きくすると明るく光る"
ColorReactionSweepColorTip<public><localizes>:message = "場所だけを狙っているときの色。1 より大きくすると明るく光る"

# laser_damage_reaction_component
DamageReactionAmountTip<public><localizes>:message = "1 回に与えるダメージ。0 で与えない。既定 5"
DamageReactionIntervalTip<public><localizes>:message = "ダメージを与える間隔（秒）。小さいほど激しい。既定 0.5"

# laser_player_target_component
PlayerTargetRangeTip<public><localizes>:message = "プレイヤーを狙い始める距離（cm）。外れると消える。既定 1500"
PlayerTargetAimHeightTip<public><localizes>:message = "キャラクターの足元から狙う高さ（cm。マイナスで下）。既定 100"

# laser_sweep_target_component
SweepTargetRadiusTip<public><localizes>:message = "掃射する円の半径（cm）。既定 600"
SweepTargetSpeedTip<public><localizes>:message = "円を回る速さ（度 / 秒）。マイナスで逆回り。既定 60"
SweepTargetHeightTip<public><localizes>:message = "目から見た円の高さ（cm。マイナスで下）。既定 -300"

# laser_marker_target_component
MarkerTargetRangeTip<public><localizes>:message = "目印を狙い始める距離（cm）。外れると消える。既定 2000"
