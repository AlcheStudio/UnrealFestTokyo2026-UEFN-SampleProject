using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }

# 入口に挑戦者が入った
# 向き：game_entrance_component が入口の entity から SendUp。受け手：親の game_loop_component。消費しない
game_join_event<public> := class(scene_event):
    # 送り元の入口
    Entrance<public>:game_entrance_component
    # 入った人
    Agent<public>:agent

# ゲームが始まった
# 向き：game_loop_component がループの entity から SendDown。受け手：子孫（HUD・アイテム付与・NPC スポナー）。消費しない
game_started_event<public> := class(scene_event):
    # 送り元のループ
    Loop<public>:game_loop_component
    # 挑戦者
    Agent<public>:agent

# ゲームが終わった（クリア・失敗・挑戦者の退出のどれでも）
# 向き：game_started_event と同じ。消費しない
game_ended_event<public> := class(scene_event):
    Loop<public>:game_loop_component
    # 挑戦していた人
    Agent<public>:agent

# 画面の真ん中の文字。空の文字で消す
# 向き：game_started_event と同じ。受け手：game_hud_component。消費しない
game_center_text_event<public> := class(scene_event):
    Loop<public>:game_loop_component
    Text<public>:string

# 画面の上の状態の文字。空の文字で消す
# 向き：game_started_event と同じ。受け手：game_hud_component。消費しない
game_status_text_event<public> := class(scene_event):
    Loop<public>:game_loop_component
    Text<public>:string

# NPC を倒す段階の entity に付けるタグ。NPC の振る舞いがこのタグで段階を探す（デバイスへの参照を持たないため）
game_defeat_target_tag<public> := class(tag):
