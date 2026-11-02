# PathSystem の @editable の説明とカテゴリ（ToolTip と Categories に使う）
# Kit（BodyKit / MotionKit）は PathSystem の中の module なので、ここの名前がそのまま見える
PathCategory<public><localizes>:message = "パス"

# path_point_component
PointOrderTip<public><localizes>:message = "点をたどる順番。小さいほど先。点どうしで重ねない。既定 0"
PointHideInGameTip<public><localizes>:message = "true：ゲーム中は目印のメッシュを隠す（当たりも消す）。既定 true"

# path_runner_component
RunnerWaitTimeTip<public><localizes>:message = "点に着いてから次へ動き出すまでの秒数。0 で止まらない。既定 0.5"

# path_guide_line_component
GuideLineColorTip<public><localizes>:message = "点をつなぐ線の色。1 より大きくすると明るく光る"

# path_cube_body_component
CubeBodySizeTip<public><localizes>:message = "キューブの大きさ（倍率。1 = 1 m）。既定 0.6"
CubeBodyColorTip<public><localizes>:message = "キューブの色"

# path_cylinder_body_component
CylinderBodySizeTip<public><localizes>:message = "円柱の大きさ（倍率。1 = 半径 50 cm、高さ 1 m）。既定 1.5"
CylinderBodyColorTip<public><localizes>:message = "ホログラムの円柱の色"

# path_marked_cube_body_component
MarkedCubeBodySizeTip<public><localizes>:message = "目印付きキューブの大きさ（倍率。1 = 1 m）。既定 0.6"
MarkedCubeBodyColorTip<public><localizes>:message = "目印付きキューブの色"

# path_linear_motion_component
LinearMotionSpeedTip<public><localizes>:message = "まっすぐ動く速さ（cm / 秒）。1 未満は 1 として扱う。既定 300"

# path_hop_motion_component
HopMotionHopHeightTip<public><localizes>:message = "跳ぶ高さ（cm）。0 でまっすぐ動く。既定 250"
HopMotionHopTimeTip<public><localizes>:message = "1 回の跳躍にかける秒数。距離によらず一定。既定 1.2"
