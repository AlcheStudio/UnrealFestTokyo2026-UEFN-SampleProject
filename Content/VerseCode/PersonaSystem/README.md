# PersonaSystem

公式の `persona_component`（AI の NPC）を Verse から使うサンプルです。NPC スポナーで出した NPC に近づいて声で会話するもの、言葉で指示を出すもの、話しかけてくるだけのもの、インタラクトで質問して文字で答えを受け取るものがあります。

> **注意**（公式ドキュメントより）
> - 実験的な機能です。プロジェクト設定で Scene Graph の実験的機能と LLM 会話を有効にする必要があり、有効にした島は公開できません。
> - プレイヤー側はボイスチャットが必須です。
> - NPC の返答は現在英語のみです（性格の指示は日本語でも渡せます）。
> - `persona_component` は、NPC キャラクター定義（カスタム NPC タイプ）に Persona モディファイアを付けると NPC に自動で付きます。Verse からは読むだけで、付けることはしません。
> - NPC 定義の振る舞いには Verse の `npc_behavior` を指定します（ここでは `persona_npc_behavior`）。振る舞いが無い NPC は、Verse から entity として読めず、`persona_component` も `GetComponent` で取れません。
> - AI の会話の記憶はラウンドごとに消えます。

## 見どころ

- **台座・振る舞い・会話の仕方を分ける**：台座（`persona_npc_component`）は「どのスポナーで出すか・どこまで近づいたら相手にするか」の設定と NPC を出すこと、NPC の振る舞い（`persona_npc_behavior`）は persona の取得・音声チャンネル・近づいた人の監視、「近づいた人とどう関わるか」は台座に付ける派生で選びます。NPC の component は NPC 自身の振る舞いからは確実に読めるので、台座から外側へ探しに行きません。
- **性格・声・割り込みは部品で選ぶ**：`persona_component` の設定はエディターから触れないので、性格は `persona_personality_component`、声と割り込みは「どの派生を付けるか」で決め、開始時に Verse から入れます。
- **文字の AI**：`persona_oracle_component` は `GetAISession()` の `Prompt` に質問と型（`oracle_answer`）を渡し、その形の答えを受け取ります。
- **Verse の書き方**：`Prompt` は待つ処理なので、インタラクトのハンドラーから `spawn{}` で呼び、`Asking` と `defer` で二重に尋ねないようにしています。結果は `GetSuccess[]` で取り出し、取れなければ失敗として扱います。

## component 一覧

| component | 役割 | 付ける場所 | 主な @editable |
|---|---|---|---|
| `persona_npc_component`（抽象・直接は付けない） | AI の NPC の台座。ラウンド開始で `Spawner` の `SpawnAt` により自分の位置に NPC を出し、どの NPC を出したかを覚える。NPC 側の処理は `persona_npc_behavior` が持ち、準備完了・近づいた・離れたを台座のフック（`OnNpcReady` / `OnPlayerNear` / `OnPlayerAway`）に知らせてくる | 台座の entity | `Spawner`, `TalkRadius` |
| └ `persona_chat_npc_component` | 近づいた人を会話相手にする（声で質問できる） | 同上 | なし |
| └ `persona_command_npc_component` | 会話に加えて（会話の部分は `persona_chat_npc_component` と同じ）、`RegisterAction` で「ついてくる / 止まる / ここに来る / ジャンプ / 踊る」を AI に教え、言葉の指示で動く | 同上 | なし |
| └ `persona_speaker_npc_component` | 近づいた人に `PromptToTalk` で自分から話しかけるだけ（会話相手にはしない） | 同上 | `Instructions` |
| └ `persona_oracle_component` | 台座でインタラクトされるたびに `Question` を NPC の AI に尋ね、答えを Print（声なし） | 台座の entity（`basic_interactable_component` とメッシュも付ける） | `Question` |
| └ `persona_guide_npc_component` | 会場の案内役。会話は `persona_chat_npc_component` と同じで、性格の代わりに役柄・会場の構成・Scene Graph / Verse / UEFN の基本（`PersonaGuideKnowledge()`、`NpcKit/PersonaGuideKnowledge.verse`）を AI に入れる | 広場の entity（`persona_personality_component` は不要） | なし |
| `persona_guide_behavior`（`persona_npc_behavior` の派生） | 案内役 NPC の振る舞い。「ついてきて / 案内して」で AI が `follow_player` を選ぶとその人についていき、「止まって」で止まる。ついていっている間、相手が別のエリア（床の `area_label_component`）に入るたび、その `Summary` を元に 2〜3 文で紹介する（会話の履歴に残るので、続けて質問できる） | 案内役の NPC キャラクター定義の振る舞いに指定 | `CanFollow`, `FollowDistance` |
| `persona_subtitle_component` | NPC が話している文章（英語）を、近くにいるプレイヤーの画面の下中央に字幕として出す（半透明の黒い帯、横幅 `MaxWidth` で折り返し）。話し終わると消える。付けなければ字幕は出ない | 台座の entity | `TextSize`, `MaxWidth`, `Margin`, `BackgroundOpacity`, `TextColor` |
| `persona_personality_component` | NPC の性格（AI への指示）を入れる | 台座の entity | `Personality` |
| `persona_voice_component`（抽象・直接は付けない） | NPC の声を決める。声は派生で選ぶ | 台座の entity | なし |
| └ `persona_narrator_voice_component` / `persona_refined_voice_component` / `persona_comic_voice_component` / `persona_tough_voice_component` / `persona_deep_voice_component` | 語り手 / 上品 / おどけた / 力強い / 低い語り の声 | 同上 | なし |
| `persona_interrupt_component`（抽象・直接は付けない） | 話している最中に話しかけられたときの扱い（`PromptInterruptionRule`）を決める | 台座の entity | なし |
| └ `persona_finish_first_component` / `persona_stop_on_hear_component` / `persona_switch_on_answer_component` | 最後まで話す / 話しかけられたらすぐやめる / 新しい答えができたら切り替える | 同上 | なし |
| `persona_npc_behavior`（`npc_behavior`） | ペルソナ NPC の振る舞い（NPC の中で動くので自分の `persona_component` を確実に読める）。自分を出した台座を探し、台座の entity の性格・声・割り込みを persona に入れ、音声チャンネルを作って自分を入れ、`TalkRadius` 内に来たプレイヤーをチャンネルに入れて台座のフックを呼ぶ。NPC が消えるときにチャンネルを片付ける | NPC キャラクター定義の振る舞いに指定 | なし |

スポナーは台座の `Spawner` にエディターで割り当てます。1 台座に 1 スポナーで、自動スポーンは切っておきます（Verse の `SpawnAt` でだけ出ます）。

NPC 定義（カスタム NPC タイプ）の前提：Persona モディファイアを付け、振る舞いに `persona_npc_behavior` を指定します。`PersonaCommandNpc` は移動・ジャンプ・エモートに `npc_actions_component` と `guard_actions_component` を使うので、ガードの種類にします。

データ：`oracle_answer`（`Answer`）、`persona_npc_member_info`（音声チャンネルで話せるか）、`npc_order`（指示を受けたことを AI が返す形）

## イベントの流れ

```
台座（persona_npc_component と派生）
  ラウンド開始：Spawner.Reset → Spawner.SpawnAt(自分の位置) → 出た NPC を覚える（生きていれば出し直さない）

NPC の振る舞い（persona_npc_behavior。NPC が出ると OnBegin が動く）
  自分の persona_component を読む → 自分を出した台座（Owns）を探す
  → 台座の entity の性格・声・割り込みを ApplyTo
  → voice_channel と agent_group を作り、自分をグループに入れ、チャンネルをシミュレーションの entity に登録
  → 台座の OnNpcReady（派生）
  0.25 秒ごと：TalkRadius 内に入った人 → AddMember → 台座の OnPlayerNear（派生）
                出た人 → 台座の OnPlayerAway（派生）→ RemoveMember
  NPC が話す → CommitSayEvent → 台座のエリアに Print。台座に persona_subtitle_component があれば近くの人に字幕 → StopSayEvent で消す
  NPC が消える：近くの人を外し、チャンネルを外す

台座の派生
  chat / guide：SetConversationTarget / ClearConversationTarget
  command：上に加えて、AI が選んだ action → NavigateTo / StopNavigation / Jump / PlayRandomEmote
  speaker：PromptToTalk(Instructions) で一方的に話す
  oracle：インタラクト → spawn{ Session.Prompt(Question, oracle_answer) } → Answer を Print
```

## レベルでの置き場所

エリア中心 (-8000, 0)。台座の 800cm 後ろに、それぞれの NPC スポナーがあります（各台座の `Spawner` に、その後ろのスポナーを割り当てる）。

- `PersonaChatNpc`：会話する NPC（語り手の声・新しい答えができたら切り替える）
- `PersonaCommandNpc`：言葉の指示で動く NPC（おどけた声・話しかけられたらすぐやめる）
- `PersonaSpeakerNpc`：話すだけの NPC（上品な声・最後まで話す）
- `PersonaOracle`：インタラクトすると質問に文字で答える NPC（最後まで話す）
- `PersonaGuide`（広場、スポーン地点の横）：会場の案内役。構成や Verse の基本を声で答える（語り手の声・最後まで話す）。NPC 定義の振る舞いは `persona_guide_behavior`。「ついてきて」と言うと一緒に回り、エリアに入るたびに紹介する

## 試してみよう（案内役）

1. 広場の案内役に近づき、「ついてきて」と話す。NPC が後ろをついてくる
2. どこかのエリアの床に入る。そのエリアの紹介を話す。続けて「もう少し詳しく」「これは何に使う？」と聞ける
3. 「止まって」で止まる。NPC 定義の `persona_guide_behavior` の `CanFollow` をオフにすると、ついてこないと答える
4. 床の `area_label_component` の `Summary` を書き換えると、紹介の内容が変わる（Verse はそのまま）

## 試してみよう

1. `PersonaChatNpc` の `persona_personality_component` の `Personality` を書き換える（例：「関西弁で答える案内役」）。話し方が変わります。
2. `PersonaChatNpc` の `persona_narrator_voice_component` を外し、`persona_comic_voice_component` を付ける。Verse を変えずに声が変わります。
3. `PersonaCommandNpc` に近づき、「ついてきて」「止まって」「踊って」と話しかける。AI が指示を選び、NPC が動きます。
4. `PersonaChatNpc` の `persona_chat_npc_component` を外して `persona_speaker_npc_component` を付ける。同じ NPC が「話すだけ」に変わります。
5. `PersonaOracle` の `Question` を自分の聞きたいことに変えて、インタラクトする。答えは出力ログに出ます。

## UE5 との違い

- UE5 には同等の組み込み機能はなく、外部の AI サービスを自前でつなぐ必要があります。ここでは NPC に付いた公式の `persona_component` を読み、Verse から性格や会話相手を設定します。
