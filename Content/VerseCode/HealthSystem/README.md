# HealthSystem

entity に「自分の体力」を持たせる `health_component`（HealthPipeline）を使って、床を踏むたびにダメージを受けて色が変わり、0 で消えて数秒後に戻る「壊れるキューブ」を作るチュートリアルです。ダメージは `damage_event` という scene_event を `SendUp` で流すだけで、受け取った `health_component` が体力を減らしてくれます。

> **注意**：`/UnrealEngine.com/HealthPipeline` と `/Fortnite.com/FortHealthPipeline` は `@experimental` の API です。これらを使った島は公開（パブリッシュ）できません。学習・検証用として使ってください。

## 見どころ

- **entity ごとの体力**：`health_component` にプール（`health_pool_entry`）を足すと、プレイヤー以外の entity も体力を持てます。プールは `health_pool_tag` の派生クラスで見分けます。
- **ダメージは scene_event**：送り手は `damage_event` を組み立てて `SendUp` するだけ。受け取る側は `health_component` の `OnReceive` が処理して消費します（最初に届いた `health_component` で止まります）。
- **結果はイベントで受け取る**：`OnDamaged` / `OnDied` を `Subscribe` して、色の変更や消滅を行います。`OnDied` は体力が 0 になった瞬間に 1 回だけ鳴ります。
- **復活は spawn と race**：`OnDied` の中では待たず、`spawn{}` した関数で `Sleep` と `StopSignal` を `race` させます。終了時にも安全に止まります。
- **ゾーンの再利用**：`damage_zone_component` は継承をせず、出入りの検知は同じ entity の ZoneSystem の `volume_detector_component` に任せ、その `volume_entered_event` を `OnReceive` で受けるだけです。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `breakable_cube_component` | 自分の体力プールを持ち、ダメージで `FullColor` → `EmptyColor` に色が変わり、0 で消えて `RespawnSeconds` 秒後に戻る | `SM_TutorialCube` と同じ entity | `MaxHealth`, `FullColor`, `EmptyColor`, `RespawnSeconds` |
| `damage_zone_component` | プレイヤーが入るたびに、同じ entity か最初の子 entity の `breakable_cube_component` へ `Amount` の `damage_event` を `SendUp` する | OverlapAll のメッシュ（`SM_TutorialVolumeCube`）・`volume_detector_component` と同じ entity | `Amount` |

タグ：`breakable_cube_pool_tag`（`health_pool_tag` の派生。このキューブのプールの識別子）

## イベントの流れ

```
プレイヤーがダメージの床に入る
  → volume_detector_component：SendUp(volume_entered_event)
  → damage_zone_component.OnReceive（Volume = Entity）
      → damage_event{Entries := array{health_adjustment_entry{HealthDelta := Amount}}} を組み立てる
      → キューブ entity に SendUp
          → health_component.OnReceive が体力を減らして消費（親には届かない）
              → OnDamaged：breakable_cube_component が残り割合で色を塗る
              → OnDied（0 になったとき）：メッシュを非表示・当たり判定なしにし、spawn で復活待ち
                  → RespawnSeconds 秒後：体力を MaxHealth に戻し、FullColor で塗って表示
```

## レベルでの置き場所

未配置。キューブは `SM_TutorialCube` の entity に、ダメージの床は OverlapAll のメッシュ（`SM_TutorialVolumeCube`）の子 entity に付ける。

```
DamagePad（SM_TutorialVolumeCube, OverlapAll）＋ volume_detector_component ＋ damage_zone_component
  └ Cube（SM_TutorialCube）＋ breakable_cube_component
```

## 試してみよう

1. 床を 4 回踏む（`Amount` 25 × 4 = `MaxHealth` 100）。踏むたびに色が `EmptyColor` に近づき、4 回目で消え、`RespawnSeconds` 秒後に戻ります。
2. `Amount` を 100 にすると 1 回で壊れ、`MaxHealth` を 400 にすると 16 回かかります。`Print` の残り体力で確かめてみましょう。
3. `damage_zone_component` を `breakable_cube_component` と同じ entity に付けても動きます（まず同じ entity を探し、無ければ子を探します）。
4. `damage_event` を `healing_event` に変えると回復になります。`health_component` の `OnHealed` も `Subscribe` してみましょう。
5. `health_pool_entry` を 2 つ足して（シールドと体力など）、`OnDamaged` の `Result.Results` でどのプールが減ったか（`PoolTag`）を見てみましょう。

## UE5 との違い

- UE5 では体力は自分で `float` を持って `AnyDamage` / `TakeDamage` を実装するか、Gameplay Ability System の Attribute を使います。Scene Graph では `health_component` が共通の受け皿で、プレイヤーも物も同じ `damage_event` で扱えます。
- `ApplyDamage` のように相手を指定して呼ぶのではなく、scene_event を `SendUp` で親子関係に沿って流し、最初に受け取った `health_component` が消費します。
- ダメージの補正（防御力・弱点など）は Blueprint で計算する代わりに、イベント・プール・component の 3 層の modifier stack で掛け算されます（このサンプルでは使っていません）。
