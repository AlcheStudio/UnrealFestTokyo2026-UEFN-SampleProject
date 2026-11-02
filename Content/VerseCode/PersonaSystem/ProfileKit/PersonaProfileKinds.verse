using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Conversations }

# AI の NPC の声と割り込みの扱いの派生（ProfileKit）。どれを付けるかで選ぶ
# 置き方：エディターで persona_component（または persona_npc_component の派生）と同じ entity に、声を 1 つ、割り込みを 1 つ付ける

# 落ち着いた語り手（Narrator, Med, Warm）
persona_narrator_voice_component<public> := class(persona_voice_component):
    MakeVoice<override>()<transacts>:voice_model = moxie_voice{}

# 上品でやわらかい（Refined, Med, Warm）
persona_refined_voice_component<public> := class(persona_voice_component):
    MakeVoice<override>()<transacts>:voice_model = elmira_voice{}

# 明るくおどけた（Comic, High, Natural）
persona_comic_voice_component<public> := class(persona_voice_component):
    MakeVoice<override>()<transacts>:voice_model = orin_voice{}

# 力強い（Tough, Med, Natural）
persona_tough_voice_component<public> := class(persona_voice_component):
    MakeVoice<override>()<transacts>:voice_model = halley_voice{}

# 太く低い語り（Narrator, Low, Warm）
persona_deep_voice_component<public> := class(persona_voice_component):
    MakeVoice<override>()<transacts>:voice_model = terns_voice{}

# 話し終わるまで聞かない
persona_finish_first_component<public> := class(persona_interrupt_component):
    GetRule<override>()<transacts>:persona_interruption_rule = persona_interruption_rule.IgnoreUntilFinished

# 話しかけられた瞬間にやめる
persona_stop_on_hear_component<public> := class(persona_interrupt_component):
    GetRule<override>()<transacts>:persona_interruption_rule = persona_interruption_rule.InterruptOnPromptStart

# 新しい答えができたところで切り替える
persona_switch_on_answer_component<public> := class(persona_interrupt_component):
    GetRule<override>()<transacts>:persona_interruption_rule = persona_interruption_rule.InterruptOnResponseStart
