# EventTreeSystem の @editable の説明とカテゴリ（ToolTip と Categories に使う）
EventTreeCategory<public><localizes>:message = "イベントツリー"

# tree_send_down_component
SendDownIntervalTip<public><localizes>:message = "イベントを流す周期（秒）。0.5 秒前にグレーへ戻す。既定 3"

# tree_node_component
NodePassTip<public><localizes>:message = "true：イベントを子へ通す（成功）。false：ここで止める（失敗）"

# tree_mesh_color_component
MeshColorSucceededColorTip<public><localizes>:message = "成功（イベントを通した）ときにキューブを塗る色"
MeshColorFailedColorTip<public><localizes>:message = "失敗（イベントを止めた）ときにキューブを塗る色"
MeshColorUnreachedColorTip<public><localizes>:message = "未到達（イベントが届いていない）ときにキューブを塗る色"

# tree_particle_component
ParticleSucceededParticleTip<public><localizes>:message = "成功（イベントを通した）ときに出すパーティクル。未設定で出さない"
ParticleFailedParticleTip<public><localizes>:message = "失敗（イベントを止めた）ときに出すパーティクル。未設定で出さない"
ParticleUnreachedParticleTip<public><localizes>:message = "未到達のときに出すパーティクル。未設定で出さない"
ParticleHeightTip<public><localizes>:message = "entity の位置からどれだけ上に出すか（cm。マイナスで下）。既定 120"

# tree_scale_component
ScaleSucceededScaleTip<public><localizes>:message = "成功（イベントを通した）ときの大きさ（倍率）。既定 1.4"
ScaleFailedScaleTip<public><localizes>:message = "失敗（イベントを止めた）ときの大きさ（倍率）。既定 0.6"
ScaleUnreachedScaleTip<public><localizes>:message = "未到達（イベントが届いていない）ときの大きさ（倍率）。既定 1"
