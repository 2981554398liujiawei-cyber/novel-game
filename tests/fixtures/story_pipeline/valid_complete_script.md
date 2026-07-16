# TASK

```story-meta
{
  "quest": {
    "schema_version": "1.5.0",
    "quest_id": "TEST_STORY_PIPELINE",
    "content_status": "complete_script",
    "title": "技术测试剧情",
    "region_id": "TEST_REGION",
    "category": "main",
    "design": {"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9,"j":10},
    "prerequisites": [],
    "mutual_exclusions": [],
    "trigger": {"method":"test","location_id":"TEST_LOC","conditions":[],"opening_presentation":{}},
    "scenes": [{"scene_id":"test_scene","title":"测试场景","entry_nodes":["start"],"exit_nodes":["done"],"participant_ids":["TEST_NPC"],"objective":"验证转换","optional_interactions":[]}],
    "entry_node": "start",
    "mechanics": [{"type":"test"}],
    "branch_summary": [{"branch":"a_or_b"}],
    "continuations": [{"type":"normal","node_id":"done"}],
    "rewards": [{"type":"signal_only","reward_id":"TEST_REWARD"}],
    "world_changes": [{"type":"none"}],
    "post_quest_feedback": [{"text":"技术测试结束后，系统留下明确且可追踪的反馈。"}],
    "implementation": {"owner":"story","version":1,"reviewed":true,"offline":true,"notes":"fixture"},
    "allowed_loops": [],
    "test_cases": [
      {"test_id":"a","initial_state":{},"steps":["start"],"expected":["done"]},
      {"test_id":"b","initial_state":{},"steps":["start"],"expected":["done"]},
      {"test_id":"c","initial_state":{},"steps":["start"],"expected":["done"]}
    ]
  },
  "baseline": {"min_visible_text_chars":0,"min_nodes":1,"min_dialogue_nodes":0,"min_choice_nodes":0,"min_terminal_nodes":1,"required_node_ids":[]},
  "ownership": {"conditions":"GameState","effects":"GameState","quest_actions":"QuestManager","item_rewards":"InventoryManager","combat_id":"CombatRunner","relationship_actions":"RelationshipManager","expression":"MainUI","gesture":"MainUI","portrait_action":"MainUI","camera":"MainUI","delivery":"MainUI"}
}
```

```story-node
{"node_id":"start","type":"narrative","location_id":"TEST_LOC","scene_id":"test_scene","purpose":"opening","text":["这是一段足够完整的技术测试旁白，用来验证受约束Markdown能够稳定转换为结构化剧情数据。"],"next":"talk_one","background_id":"TEST_BG","music_id":"TEST_MUSIC","audio_cue":"TEST_SFX"}
```

```story-node
{"node_id":"talk_one","type":"dialogue","location_id":"TEST_LOC","scene_id":"test_scene","purpose":"prompt","speaker_id":"TEST_NPC","text":["请在两个明确选项之间作出选择，随后系统会保留全部语义并汇流。"],"expression":"neutral","portrait_action":"show","gesture":"none","camera":"none","delivery":"normal","next":"choose"}
```

```story-node
{"node_id":"choose","type":"choice","location_id":"TEST_LOC","scene_id":"test_scene","purpose":"choice","choices":[{"choice_id":"choose_a","text":"选择第一条可验证路径","intent":"test_a","protagonist_boundary":"allowed","visible_risk":"none","consequence_summary":"进入A","hidden_consequence":"none","goto":"talk_a","conditions":[{"key":"test.flag","op":"eq","value":false}],"effects":[{"key":"test.flag","op":"set","value":true}]},{"choice_id":"choose_b","text":"选择第二条可验证路径","intent":"test_b","protagonist_boundary":"allowed","visible_risk":"none","consequence_summary":"进入B","hidden_consequence":"none","goto":"talk_b"}]}
```

```story-node
{"node_id":"talk_a","type":"dialogue","location_id":"TEST_LOC","scene_id":"test_scene","purpose":"response_a","speaker_id":"TEST_NPC","text":["第一条路径已被系统确认，并给出不会丢失的即时回应。"],"expression":"neutral","portrait_action":"keep","gesture":"none","camera":"none","delivery":"normal","relationship_actions":[{"relationship_id":"TEST_RELATIONSHIP","dimension":"trust","op":"inc","value":1}],"next":"done"}
```

```story-node
{"node_id":"talk_b","type":"dialogue","location_id":"TEST_LOC","scene_id":"test_scene","purpose":"response_b","speaker_id":"TEST_NPC","text":["第二条路径同样获得清晰回应，然后安全汇入共同出口。"],"expression":"neutral","portrait_action":"keep","gesture":"none","camera":"none","delivery":"normal","next":"done"}
```

```story-node
{"node_id":"done","type":"complete","location_id":"TEST_LOC","scene_id":"test_scene","purpose":"complete","terminal":true,"outcome":"test_complete"}
```
