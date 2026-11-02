using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }

# 役割：ゲームが始まったら（game_started_event）NPC スポナーを有効にして NPC を出し、
#       終わったら（game_ended_event）無効にして NPC を消す
# 置き方：エディターで entity に付け、Spawner に NPC スポナーを入れる。NPC を出したいゲームループに 1 つ
# 親：game_loop_component の entity の直下
# 前提：NPC スポナーは「ゲーム開始時に有効」をオフ、「有効になったらスポーン」と「無効で NPC を消す」をオン
game_npc_spawner_component<public> := class<final_super>(component):

    # 動かす NPC スポナー
    @editable:
        ToolTip := NpcSpawnerSpawnerTip
        Categories := array{GameLoopNpcCategory}
    Spawner<public>:npc_spawner_device = npc_spawner_device{}

    OnSimulate<override>()<suspends>:void =
        # デバイスの準備を待つため、OnBeginSimulation ではなくここで無効にする（デバイス側も「ゲーム開始時に有効」はオフ）
        Spawner.Disable()

    OnReceive<override>(SceneEvent:scene_event):logic =
        if (game_started_event[SceneEvent]):
            Spawner.Reset()
            Spawner.Enable()
        else if (game_ended_event[SceneEvent]):
            Spawner.Disable()
            Spawner.DespawnAll(false)
        false
