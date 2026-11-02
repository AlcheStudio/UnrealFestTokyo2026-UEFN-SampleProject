using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Fortnite.com/Game }

# ラウンドが始まるたびに Body を動かす（fort_round_manager の SubscribeRoundStarted）
#   ラウンドがすでに進行中なら、すぐに動き出す。ラウンドが終わると Body は自動でキャンセルされる
#   試合が始まる前（ロビー）には何も動かないので、プレイヤーの出入りや NPC の生成はラウンドの中だけで起きる
#   戻り値の cancelable は OnEndSimulation で Cancel する。round manager が取れなければ false
(Owner:entity).SubscribeRounds<public>(Body:type{_()<suspends>:void}):?cancelable =
    if (Manager := Owner.GetFortRoundManager[]):
        Subscription := Manager.SubscribeRoundStarted(Body)
        option{Subscription}
    else:
        Print("[round] fort_round_manager が見つからない")
        false

# ラウンドが終わったときに Body を呼ぶ（fort_round_manager の SubscribeRoundEnded）。後片付けに使う
(Owner:entity).SubscribeRoundEnds<public>(Body:type{_():void}):?cancelable =
    if (Manager := Owner.GetFortRoundManager[]):
        Subscription := Manager.SubscribeRoundEnded(Body)
        option{Subscription}
    else:
        Print("[round] fort_round_manager が見つからない")
        false
