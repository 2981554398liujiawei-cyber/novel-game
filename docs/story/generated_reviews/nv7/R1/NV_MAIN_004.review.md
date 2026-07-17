# 狼影中的同伴

> 本文件由运行JSON自动生成，只供审阅；请勿手工作为权威源修改。

## 元数据

```json
{
  "schema_version": "1.5.0",
  "quest_id": "NV_MAIN_004",
  "content_status": "data_ready",
  "title": "狼影中的同伴",
  "region_id": "NV7",
  "category": "main",
  "design": {
    "purpose": "第七新手村R1正式接入",
    "theme": "被困世界中的求证与协作",
    "emotion": "异常、试探、行动",
    "source": "审核通过的R1.1完整剧本包",
    "adaptation": "机械结构化，不改写核心台词",
    "conflict": "玩家在真实风险中判断行动",
    "mechanic": "对话、选择、任务与战斗引用",
    "start": "王五带来的坏消息",
    "end": "护腕与下一站",
    "feedback": "保留任务后回访"
  },
  "prerequisites": [],
  "mutual_exclusions": [],
  "trigger": {
    "method": "story_chain",
    "location_id": "NV7_LOC_SQUARE",
    "conditions": [],
    "opening_presentation": {}
  },
  "scenes": [
    {
      "scene_id": "s01",
      "title": "王五带来的坏消息",
      "entry_nodes": [
        "s01_001"
      ],
      "exit_nodes": [
        "s01_020"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_LANYIN",
        "NV7_NPC_WANGWU",
        "NV7_NPC_TIANHUOLENGHUN",
        "NV7_NPC_FENGYUN_SHIHU",
        "NV7_NPC_FENGYUN_HEIHU",
        "NV7_NPC_FENGYUN_HUANGHU"
      ],
      "objective": "王五带来的坏消息",
      "optional_interactions": []
    },
    {
      "scene_id": "s02",
      "title": "高石上的“战术”",
      "entry_nodes": [
        "s02_001"
      ],
      "exit_nodes": [
        "s02_choice_1"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_LANYIN",
        "NV7_NPC_WANGWU",
        "NV7_NPC_TIANHUOLENGHUN",
        "NV7_NPC_FENGYUN_SHIHU",
        "NV7_NPC_FENGYUN_HEIHU",
        "NV7_NPC_FENGYUN_HUANGHU"
      ],
      "objective": "高石上的“战术”",
      "optional_interactions": []
    },
    {
      "scene_id": "s03",
      "title": "现实不是秘密，但也不是闲聊",
      "entry_nodes": [
        "s03_001"
      ],
      "exit_nodes": [
        "s03_036"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_LANYIN",
        "NV7_NPC_WANGWU",
        "NV7_NPC_TIANHUOLENGHUN",
        "NV7_NPC_FENGYUN_SHIHU",
        "NV7_NPC_FENGYUN_HEIHU",
        "NV7_NPC_FENGYUN_HUANGHU"
      ],
      "objective": "现实不是秘密，但也不是闲聊",
      "optional_interactions": []
    },
    {
      "scene_id": "s04",
      "title": "风云三人组",
      "entry_nodes": [
        "s04_001"
      ],
      "exit_nodes": [
        "s04_choice_2"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_LANYIN",
        "NV7_NPC_WANGWU",
        "NV7_NPC_TIANHUOLENGHUN",
        "NV7_NPC_FENGYUN_SHIHU",
        "NV7_NPC_FENGYUN_HEIHU",
        "NV7_NPC_FENGYUN_HUANGHU"
      ],
      "objective": "风云三人组",
      "optional_interactions": []
    },
    {
      "scene_id": "s05",
      "title": "山狼王三方战",
      "entry_nodes": [
        "s05_001"
      ],
      "exit_nodes": [
        "s05_090"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_LANYIN",
        "NV7_NPC_WANGWU",
        "NV7_NPC_TIANHUOLENGHUN",
        "NV7_NPC_FENGYUN_SHIHU",
        "NV7_NPC_FENGYUN_HEIHU",
        "NV7_NPC_FENGYUN_HUANGHU"
      ],
      "objective": "山狼王三方战",
      "optional_interactions": []
    },
    {
      "scene_id": "s06",
      "title": "战败续接",
      "entry_nodes": [
        "s06_001"
      ],
      "exit_nodes": [
        "s06_024"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_LANYIN",
        "NV7_NPC_WANGWU",
        "NV7_NPC_TIANHUOLENGHUN",
        "NV7_NPC_FENGYUN_SHIHU",
        "NV7_NPC_FENGYUN_HEIHU",
        "NV7_NPC_FENGYUN_HUANGHU"
      ],
      "objective": "战败续接",
      "optional_interactions": []
    },
    {
      "scene_id": "s07",
      "title": "旧猎棚的分配",
      "entry_nodes": [
        "s07_001"
      ],
      "exit_nodes": [
        "s07_choice_4"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_LANYIN",
        "NV7_NPC_WANGWU",
        "NV7_NPC_TIANHUOLENGHUN",
        "NV7_NPC_FENGYUN_SHIHU",
        "NV7_NPC_FENGYUN_HEIHU",
        "NV7_NPC_FENGYUN_HUANGHU"
      ],
      "objective": "旧猎棚的分配",
      "optional_interactions": []
    },
    {
      "scene_id": "s08",
      "title": "护腕与下一站",
      "entry_nodes": [
        "s08_001"
      ],
      "exit_nodes": [
        "s08_050"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_LANYIN",
        "NV7_NPC_WANGWU",
        "NV7_NPC_TIANHUOLENGHUN",
        "NV7_NPC_FENGYUN_SHIHU",
        "NV7_NPC_FENGYUN_HEIHU",
        "NV7_NPC_FENGYUN_HUANGHU"
      ],
      "objective": "护腕与下一站",
      "optional_interactions": []
    }
  ],
  "entry_node": "s01_001",
  "mechanics": [
    {
      "type": "story_choice"
    },
    {
      "type": "manager_integration"
    }
  ],
  "branch_summary": [
    {
      "branch": "reviewed_choices_preserved"
    }
  ],
  "continuations": [
    {
      "type": "normal",
      "node_id": "story_complete"
    },
    {
      "type": "failure",
      "node_id": "s08_001"
    }
  ],
  "rewards": [
    {
      "type": "signal_only",
      "reward_id": "NV_MAIN_004_REWARD"
    }
  ],
  "world_changes": [
    {
      "type": "registered_state_only"
    }
  ],
  "post_quest_feedback": [
    {
      "text": "任务后回访内容已保留在结构化节点中。"
    }
  ],
  "implementation": {
    "owner": "story",
    "version": 1,
    "reviewed": true,
    "offline": true,
    "notes": "R1.1审核包机械结构化；迁移映射见生成报告。",
    "story_pipeline_extensions": {
      "s01_001": {
        "foreshadowing_refs": [
          "PLAYERS_TRAPPED",
          "GREED_RING",
          "LANYIN_CHARACTER_ARC"
        ]
      }
    }
  },
  "runtime": {
    "status_state_key": "quest.nv_main_004.status",
    "reward_granted_state_key": "quest.nv_main_004.reward_granted",
    "availability": {
      "all": [
        {
          "kind": "quest",
          "quest_id": "NV_MAIN_003",
          "op": "eq",
          "value": "completed"
        }
      ],
      "any": []
    },
    "objectives": [
      {
        "objective_id": "resolve_wolf_event",
        "type": "boolean",
        "required": true,
        "progress_state_key": "quest.nv_main_004.objective.resolve_wolf_event",
        "target": true
      }
    ],
    "completion_mode": "automatic",
    "failure": {
      "continuation_state_key": "quest.nv_main_004.continuation",
      "allowed_continuations": [
        "none",
        "wolf_path_recovery"
      ],
      "resume_from_failed": "active",
      "resume_from_suspended": "active",
      "reopen_allowed": true
    }
  },
  "allowed_loops": [],
  "test_cases": [
    {
      "test_id": "nv_main_004_start",
      "initial_state": {},
      "steps": [
        "s01_001"
      ],
      "expected": [
        "story_started"
      ]
    },
    {
      "test_id": "nv_main_004_route",
      "initial_state": {},
      "steps": [
        "s01_001"
      ],
      "expected": [
        "choice_or_dialogue"
      ]
    },
    {
      "test_id": "nv_main_004_complete",
      "initial_state": {},
      "steps": [
        "s01_001"
      ],
      "expected": [
        "story_complete"
      ]
    }
  ]
}
```

## 节点 `s01_001`

```json
{
  "node_id": "s01_001",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "王五把一截被咬断的皮带扔在桌上。"
  ],
  "next": "s01_002",
  "quest_actions": [
    {
      "action": "activate",
      "quest_id": "NV_MAIN_004"
    }
  ],
  "effects": [
    {
      "key": "world.nv7.adventurers_trapped_confirmed",
      "op": "set",
      "value": true
    },
    {
      "key": "world.nv7.wangwu_injury_stage",
      "op": "set",
      "value": "light"
    }
  ]
}
```

## 节点 `s01_002`

```json
{
  "node_id": "s01_002",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "狼径出问题了。"
  ],
  "next": "s01_003"
}
```

## 节点 `s01_003`

```json
{
  "node_id": "s01_003",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "狼？"
  ],
  "next": "s01_004"
}
```

## 节点 `s01_004`

```json
{
  "node_id": "s01_004",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "不止。"
  ],
  "next": "s01_005"
}
```

## 节点 `s01_005`

```json
{
  "node_id": "s01_005",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "刺猬堵路，鹿往低地跑，山狼离开原来的窝。"
  ],
  "next": "s01_006"
}
```

## 节点 `s01_006`

```json
{
  "node_id": "s01_006",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音接过皮带闻了闻。"
  ],
  "next": "s01_007"
}
```

## 节点 `s01_007`

```json
{
  "node_id": "s01_007",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "蓝粉。"
  ],
  "next": "s01_008"
}
```

## 节点 `s01_008`

```json
{
  "node_id": "s01_008",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "还有个冒险者没回来。"
  ],
  "next": "s01_009"
}
```

## 节点 `s01_009`

```json
{
  "node_id": "s01_009",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "谁？"
  ],
  "next": "s01_010"
}
```

## 节点 `s01_010`

```json
{
  "node_id": "s01_010",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "天火冷魂。"
  ],
  "next": "s01_011"
}
```

## 节点 `s01_011`

```json
{
  "node_id": "s01_011",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "王五顿了顿。"
  ],
  "next": "s01_012"
}
```

## 节点 `s01_012`

```json
{
  "node_id": "s01_012",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "嘴比刀快。"
  ],
  "next": "s01_013"
}
```

## 节点 `s01_013`

```json
{
  "node_id": "s01_013",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "腿没嘴快。"
  ],
  "next": "s01_014"
}
```

## 节点 `s01_014`

```json
{
  "node_id": "s01_014",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你对失踪人口评价挺完整。"
  ],
  "next": "s01_015"
}
```

## 节点 `s01_015`

```json
{
  "node_id": "s01_015",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "见过他一次就够了。"
  ],
  "next": "s01_016"
}
```

## 节点 `s01_016`

```json
{
  "node_id": "s01_016",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "若玩家取得完整账册："
  ],
  "next": "s01_017"
}
```

## 节点 `s01_017`

```json
{
  "node_id": "s01_017",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月拿出异常活体收购信息。"
  ],
  "next": "s01_018"
}
```

## 节点 `s01_018`

```json
{
  "node_id": "s01_018",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "王五看完后："
  ],
  "next": "s01_019"
}
```

## 节点 `s01_019`

```json
{
  "node_id": "s01_019",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "兔、狼、大型兽。"
  ],
  "next": "s01_020"
}
```

## 节点 `s01_020`

```json
{
  "node_id": "s01_020",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "下一批要是连人也收，我都不奇怪。"
  ],
  "next": "s02_001"
}
```

## 节点 `s02_001`

```json
{
  "node_id": "s02_001",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂站在一块高石上，脚边只剩三块石头。"
  ],
  "next": "s02_002"
}
```

## 节点 `s02_002`

```json
{
  "node_id": "s02_002",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "先说明！"
  ],
  "next": "s02_003"
}
```

## 节点 `s02_003`

```json
{
  "node_id": "s02_003",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“我不是被困！”"
  ],
  "next": "s02_004"
}
```

## 节点 `s02_004`

```json
{
  "node_id": "s02_004",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“我只是在高处重新制定战术！”"
  ],
  "next": "s02_005"
}
```

## 节点 `s02_005`

```json
{
  "node_id": "s02_005",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音抬眼。"
  ],
  "next": "s02_006"
}
```

## 节点 `s02_006`

```json
{
  "node_id": "s02_006",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "你的战术只剩三块石头。"
  ],
  "next": "s02_007"
}
```

## 节点 `s02_007`

```json
{
  "node_id": "s02_007",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "战术不看数量，看质量。"
  ],
  "next": "s02_008"
}
```

## 节点 `s02_008`

```json
{
  "node_id": "s02_008",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "一只刺猬王撞上石壁。"
  ],
  "next": "s02_009"
}
```

## 节点 `s02_009`

```json
{
  "node_id": "s02_009",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "……现在质量也一般。"
  ],
  "next": "s02_choice_1"
}
```

## 节点 `s02_choice_1_1_response`

```json
{
  "node_id": "s02_choice_1_1_response",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“你跳的时候别砸我。”",
    "天火冷魂：“你先把下面那只大的弄开！”",
    "进入直接救援战。"
  ],
  "next": "s03_001",
  "relationship_actions": [
    {
      "relationship_id": "NV7_REL_FENGYUE_TIANHUOLENGHUN",
      "dimension": "trust",
      "op": "inc",
      "value": 1
    },
    {
      "relationship_id": "NV7_REL_FENGYUE_TIANHUOLENGHUN",
      "action": "set_flag",
      "flag_id": "owes_fengyue_rescue",
      "value": true
    }
  ]
}
```

## 节点 `s02_choice_1_2_response`

```json
{
  "node_id": "s02_choice_1_2_response",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月没有立刻下坡。",
    "刺猬王每次冲撞石壁后都会停两秒，把背朝向左侧斜坡。",
    "枫月：“它们每次冲撞后会停。”",
    "岚音：“你终于会先看了。”",
    "玩家下一步可选择：",
    "【在停顿时滚下枯木】：完全成功，刺猬群被声响引向另一侧；",
    "【提前滚木】：部分成功，小刺猬被引开，刺猬王仍留在原地；",
    "【等太久】：刺猬王改换冲撞方向，天火冷魂脚下石块松动，救援压力增加。",
    "完全成功时：",
    "天火冷魂跳下后：“我本来也是这么想的。”",
    "枫月：“你手里那三块石头不同意。”",
    "部分成功时：",
    "只进入刺猬王单体战。",
    "岚音：“观察不是为了看得更久。”",
    "枫月：“是为了少打一只。”",
    "岚音：“你学得挺快。”"
  ],
  "next": "s03_001"
}
```

## 节点 `s02_choice_1_3_response`

```json
{
  "node_id": "s02_choice_1_3_response",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“你吸引左边，我开右侧出口。”",
    "天火冷魂：“凭什么我吸引？”",
    "枫月：“因为它们已经认识你了。”",
    "合作成功，关系增加较少但建立互相认可。"
  ],
  "next": "s03_001"
}
```

## 节点 `s02_choice_1_4_response`

```json
{
  "node_id": "s02_choice_1_4_response",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "岚音：“你确定？”",
    "枫月：“他暂时在高处是安全的。狼群正在移动。”",
    "岚音：“可以。”",
    "若延迟过久，天火冷魂自行跳下，造成中度伤势。",
    "他不会永久死亡。",
    "后续对白：",
    "天火冷魂：“你们真的走了？”",
    "枫月：“你说你没被困。”",
    "天火冷魂：“你怎么还信这个！”",
    "伤势由任务上下文管理，长期只在需要跨任务读取时转写到 GameState；本轮结束前可恢复为轻伤版本。"
  ],
  "next": "s03_001"
}
```

## 节点 `s02_choice_1`

```json
{
  "node_id": "s02_choice_1",
  "type": "choice",
  "scene_id": "s02",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice",
  "choices": [
    {
      "choice_id": "s02_choice_1_a1",
      "text": "立即冲进去",
      "intent": "立即冲进去",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s02_choice_1_1_response"
    },
    {
      "choice_id": "s02_choice_1_a2",
      "text": "先观察规律",
      "intent": "先观察规律",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s02_choice_1_2_response"
    },
    {
      "choice_id": "s02_choice_1_a3",
      "text": "让他配合",
      "intent": "让他配合",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s02_choice_1_3_response"
    },
    {
      "choice_id": "s02_choice_1_a4",
      "text": "暂时绕开追狼",
      "intent": "暂时绕开追狼",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s02_choice_1_4_response"
    }
  ],
  "next": "s03_001"
}
```

## 节点 `s03_001`

```json
{
  "node_id": "s03_001",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂喝了口水，盯着枫月身边的冒险者标记。"
  ],
  "next": "s03_002"
}
```

## 节点 `s03_002`

```json
{
  "node_id": "s03_002",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "你什么时候进来的？"
  ],
  "next": "s03_003"
}
```

## 节点 `s03_003`

```json
{
  "node_id": "s03_003",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "第一次登录。"
  ],
  "next": "s03_004"
}
```

## 节点 `s03_004`

```json
{
  "node_id": "s03_004",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "……那你运气真差。"
  ],
  "next": "s03_005"
}
```

## 节点 `s03_005`

```json
{
  "node_id": "s03_005",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "这句话我听不出安慰。"
  ],
  "next": "s03_006"
}
```

## 节点 `s03_006`

```json
{
  "node_id": "s03_006",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "本来就不是。"
  ],
  "next": "s03_007"
}
```

## 节点 `s03_007`

```json
{
  "node_id": "s03_007",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你进来更早？"
  ],
  "next": "s03_008"
}
```

## 节点 `s03_008`

```json
{
  "node_id": "s03_008",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂点头。"
  ],
  "next": "s03_009"
}
```

## 节点 `s03_009`

```json
{
  "node_id": "s03_009",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你也出不去？"
  ],
  "next": "s03_010"
}
```

## 节点 `s03_010`

```json
{
  "node_id": "s03_010",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂下意识看向岚音。"
  ],
  "next": "s03_011"
}
```

## 节点 `s03_011`

```json
{
  "node_id": "s03_011",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音正在远处检查脚印，但显然听得见。"
  ],
  "next": "s03_012"
}
```

## 节点 `s03_012`

```json
{
  "node_id": "s03_012",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂压低声音。"
  ],
  "next": "s03_013"
}
```

## 节点 `s03_013`

```json
{
  "node_id": "s03_013",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "少在本地居民面前说现实。"
  ],
  "next": "s03_014"
}
```

## 节点 `s03_014`

```json
{
  "node_id": "s03_014",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "系统禁止？"
  ],
  "next": "s03_015"
}
```

## 节点 `s03_015`

```json
{
  "node_id": "s03_015",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "不是。"
  ],
  "next": "s03_016"
}
```

## 节点 `s03_016`

```json
{
  "node_id": "s03_016",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "他们听得见，但很多东西根本没有概念。"
  ],
  "next": "s03_017"
}
```

## 节点 `s03_017`

```json
{
  "node_id": "s03_017",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "而且冒险者之间也不爱公开谈。"
  ],
  "next": "s03_018"
}
```

## 节点 `s03_018`

```json
{
  "node_id": "s03_018",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "为什么？"
  ],
  "next": "s03_019"
}
```

## 节点 `s03_019`

```json
{
  "node_id": "s03_019",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "现实身份、家人、仇人、钱、以前认识谁。"
  ],
  "next": "s03_020"
}
```

## 节点 `s03_020`

```json
{
  "node_id": "s03_020",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "在一个大家都出不去的地方，这些都是能拿来伤人的东西。"
  ],
  "next": "s03_021"
}
```

## 节点 `s03_021`

```json
{
  "node_id": "s03_021",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "所以你知道多少？"
  ],
  "next": "s03_022"
}
```

## 节点 `s03_022`

```json
{
  "node_id": "s03_022",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "我遇到的人里，没有一个能主动退出。"
  ],
  "next": "s03_023"
}
```

## 节点 `s03_023`

```json
{
  "node_id": "s03_023",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月沉默。"
  ],
  "next": "s03_024"
}
```

## 节点 `s03_024`

```json
{
  "node_id": "s03_024",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "你别这个表情。"
  ],
  "next": "s03_025"
}
```

## 节点 `s03_025`

```json
{
  "node_id": "s03_025",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "什么表情？"
  ],
  "next": "s03_026"
}
```

## 节点 `s03_026`

```json
{
  "node_id": "s03_026",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "像刚确认坏消息不是你一个人的，所以更坏了。"
  ],
  "next": "s03_027"
}
```

## 节点 `s03_027`

```json
{
  "node_id": "s03_027",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你观察力不错。"
  ],
  "next": "s03_028"
}
```

## 节点 `s03_028`

```json
{
  "node_id": "s03_028",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "被困久了，人总得发展点副业。"
  ],
  "next": "s03_029"
}
```

## 节点 `s03_029`

```json
{
  "node_id": "s03_029",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "GameState：world.nv7.adventurers_trapped_confirmed = true"
  ],
  "next": "s03_030"
}
```

## 节点 `s03_030`

```json
{
  "node_id": "s03_030",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音走回来。"
  ],
  "next": "s03_031"
}
```

## 节点 `s03_031`

```json
{
  "node_id": "s03_031",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "说完了？"
  ],
  "next": "s03_032"
}
```

## 节点 `s03_032`

```json
{
  "node_id": "s03_032",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "你听懂多少？"
  ],
  "next": "s03_033"
}
```

## 节点 `s03_033`

```json
{
  "node_id": "s03_033",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "你们都想回一个我们不知道在哪里的地方。"
  ],
  "next": "s03_034"
}
```

## 节点 `s03_034`

```json
{
  "node_id": "s03_034",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "差不多。"
  ],
  "next": "s03_035"
}
```

## 节点 `s03_035`

```json
{
  "node_id": "s03_035",
  "type": "dialogue",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "那就够了。"
  ],
  "next": "s03_036"
}
```

## 节点 `s03_036`

```json
{
  "node_id": "s03_036",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "此处明确：本地居民不是听不见现实词汇，只是缺乏对应概念。"
  ],
  "next": "s04_001"
}
```

## 节点 `s04_001`

```json
{
  "node_id": "s04_001",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "三个人从断树后走出。"
  ],
  "next": "s04_002"
}
```

## 节点 `s04_002`

```json
{
  "node_id": "s04_002",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_FENGYUN_SHIHU",
  "expression": "default",
  "portrait_action": "show",
  "text": [
    "天火冷魂。"
  ],
  "next": "s04_003"
}
```

## 节点 `s04_003`

```json
{
  "node_id": "s04_003",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "这么正式干什么。"
  ],
  "next": "s04_004"
}
```

## 节点 `s04_004`

```json
{
  "node_id": "s04_004",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_FENGYUN_HEIHU",
  "expression": "default",
  "portrait_action": "show",
  "text": [
    "图交出来。"
  ],
  "next": "s04_005"
}
```

## 节点 `s04_005`

```json
{
  "node_id": "s04_005",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_FENGYUN_HUANGHU",
  "expression": "default",
  "portrait_action": "show",
  "text": [
    "大家省点时间。"
  ],
  "next": "s04_006"
}
```

## 节点 `s04_006`

```json
{
  "node_id": "s04_006",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "你们三个名字都这么统一，分赃方式怎么这么不统一？"
  ],
  "next": "s04_007"
}
```

## 节点 `s04_007`

```json
{
  "node_id": "s04_007",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "石虎看向枫月。"
  ],
  "next": "s04_008"
}
```

## 节点 `s04_008`

```json
{
  "node_id": "s04_008",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_FENGYUN_SHIHU",
  "expression": "default",
  "portrait_action": "show",
  "text": [
    "新来的？"
  ],
  "next": "s04_009"
}
```

## 节点 `s04_009`

```json
{
  "node_id": "s04_009",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "看得出来？"
  ],
  "next": "s04_010"
}
```

## 节点 `s04_010`

```json
{
  "node_id": "s04_010",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_FENGYUN_SHIHU",
  "expression": "default",
  "portrait_action": "show",
  "text": [
    "不然不会站他这边。"
  ],
  "next": "s04_011"
}
```

## 节点 `s04_011`

```json
{
  "node_id": "s04_011",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "这句我不同意。"
  ],
  "next": "s04_choice_2"
}
```

## 节点 `s04_choice_2_1_response`

```json
{
  "node_id": "s04_choice_2_1_response",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“图是谁找到的，就先归谁。”",
    "石虎：“那就看谁拿得住。”",
    "GameState候选：关系阶段偏敌对，最终由任务结算写入。"
  ],
  "next": "s05_001"
}
```

## 节点 `s04_choice_2_2_response`

```json
{
  "node_id": "s04_choice_2_2_response",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“你们要图，我们要过狼径。先解决眼前的。”",
    "石虎：“怎么分？”",
    "枫月：“先活着，再谈。”",
    "黄虎笑：“这话靠谱。”",
    "关系偏警惕合作。"
  ],
  "next": "s05_001"
}
```

## 节点 `s04_choice_2_3_response`

```json
{
  "node_id": "s04_choice_2_3_response",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“我对你们的图没兴趣。”",
    "天火冷魂：“我有。”",
    "枫月：“所以那是你的事。”",
    "石虎对枫月警惕降低，但天火冷魂会评价玩家边界感。"
  ],
  "next": "s05_001"
}
```

## 节点 `s04_choice_2_4_response`

```json
{
  "node_id": "s04_choice_2_4_response",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“狼群正在靠近。谁现在动手，谁先喂狼。”",
    "黑虎：“威胁我们？”",
    "枫月：“提醒。”",
    "石虎：“行。狼王倒下之前，不动你们。”"
  ],
  "next": "s05_001"
}
```

## 节点 `s04_choice_2`

```json
{
  "node_id": "s04_choice_2",
  "type": "choice",
  "scene_id": "s04",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice",
  "choices": [
    {
      "choice_id": "s04_choice_2_b1",
      "text": "强硬拒绝",
      "intent": "强硬拒绝",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s04_choice_2_1_response"
    },
    {
      "choice_id": "s04_choice_2_b2",
      "text": "谈判",
      "intent": "谈判",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s04_choice_2_2_response"
    },
    {
      "choice_id": "s04_choice_2_b3",
      "text": "只救人，不争图",
      "intent": "只救人，不争图",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s04_choice_2_3_response"
    },
    {
      "choice_id": "s04_choice_2_b4",
      "text": "临时合作",
      "intent": "临时合作",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s04_choice_2_4_response"
    }
  ],
  "next": "s05_001"
}
```

## 节点 `s05_001`

```json
{
  "node_id": "s05_001",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "山狼王从坡顶出现。"
  ],
  "next": "s05_002"
}
```

## 节点 `s05_002`

```json
{
  "node_id": "s05_002",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "它颈部有磨破的金属痕迹，毛发间残留蓝粉。"
  ],
  "next": "s05_003"
}
```

## 节点 `s05_003`

```json
{
  "node_id": "s05_003",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "又一个。"
  ],
  "next": "s05_004"
}
```

## 节点 `s05_004`

```json
{
  "node_id": "s05_004",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "被赶出来的？"
  ],
  "next": "s05_005"
}
```

## 节点 `s05_005`

```json
{
  "node_id": "s05_005",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "王五若前期已到场："
  ],
  "next": "s05_006"
}
```

## 节点 `s05_006`

```json
{
  "node_id": "s05_006",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "不只赶。"
  ],
  "next": "s05_007"
}
```

## 节点 `s05_007`

```json
{
  "node_id": "s05_007",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "它戴过东西。"
  ],
  "next": "s05_008"
}
```

## 节点 `s05_008`

```json
{
  "node_id": "s05_008",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "战斗同时存在三种压力："
  ],
  "next": "s05_009"
}
```

## 节点 `s05_009`

```json
{
  "node_id": "s05_009",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "1. 狼群攻击"
  ],
  "next": "s05_010"
}
```

## 节点 `s05_010`

```json
{
  "node_id": "s05_010",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "2. 山狼王狂躁"
  ],
  "next": "s05_011"
}
```

## 节点 `s05_011`

```json
{
  "node_id": "s05_011",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "3. 风云三人组争夺首领掉落与藏宝图"
  ],
  "next": "s05_012"
}
```

## 节点 `s05_012`

```json
{
  "node_id": "s05_012",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "山狼王没有立即扑来，而是在坡顶来回踱步，颈部金属残片不断刮进皮肉。"
  ],
  "next": "s05_013"
}
```

## 节点 `s05_013`

```json
{
  "node_id": "s05_013",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "风云黑虎压低声音：“先集火大的。”"
  ],
  "next": "s05_014"
}
```

## 节点 `s05_014`

```json
{
  "node_id": "s05_014",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "它旁边还有四只。"
  ],
  "next": "s05_015"
}
```

## 节点 `s05_015`

```json
{
  "node_id": "s05_015",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "我支持先解决最贵的。"
  ],
  "next": "s05_016"
}
```

## 节点 `s05_016`

```json
{
  "node_id": "s05_016",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你是说最危险的？"
  ],
  "next": "s05_017"
}
```

## 节点 `s05_017`

```json
{
  "node_id": "s05_017",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "我刚才说得很清楚。"
  ],
  "next": "s05_018"
}
```

## 节点 `s05_018`

```json
{
  "node_id": "s05_018",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家选择伙伴倾向后，战斗开始。"
  ],
  "next": "s05_019"
}
```

## 节点 `s05_019`

```json
{
  "node_id": "s05_019",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若选择进攻："
  ],
  "next": "s05_020"
}
```

## 节点 `s05_020`

```json
{
  "node_id": "s05_020",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音先射一箭打断最近的灰狼扑击。"
  ],
  "next": "s05_021"
}
```

## 节点 `s05_021`

```json
{
  "node_id": "s05_021",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若选择防守："
  ],
  "next": "s05_022"
}
```

## 节点 `s05_022`

```json
{
  "node_id": "s05_022",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "她站到天火冷魂受伤侧，压低队形。"
  ],
  "next": "s05_023"
}
```

## 节点 `s05_023`

```json
{
  "node_id": "s05_023",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若选择支援："
  ],
  "next": "s05_024"
}
```

## 节点 `s05_024`

```json
{
  "node_id": "s05_024",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "她第一箭射断一根散发蓝粉的诱饵绳，狼群短暂混乱。"
  ],
  "next": "s05_025"
}
```

## 节点 `s05_025`

```json
{
  "node_id": "s05_025",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "第一阶段结束条件：处理外围狼群或稳定队形。"
  ],
  "next": "s05_026"
}
```

## 节点 `s05_026`

```json
{
  "node_id": "s05_026",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "山狼王生命下降后，系统出现高价值首领奖励提示。"
  ],
  "next": "s05_027"
}
```

## 节点 `s05_027`

```json
{
  "node_id": "s05_027",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_FENGYUN_SHIHU",
  "expression": "default",
  "portrait_action": "show",
  "text": [
    "最后一下各凭本事。"
  ],
  "next": "s05_028"
}
```

## 节点 `s05_028`

```json
{
  "node_id": "s05_028",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "你们从开打前就等这句吧？"
  ],
  "next": "s05_029"
}
```

## 节点 `s05_029`

```json
{
  "node_id": "s05_029",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若玩家此前与风云组临时合作："
  ],
  "next": "s05_030"
}
```

## 节点 `s05_030`

```json
{
  "node_id": "s05_030",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "黄虎会提醒：“先别抢，它状态不对。”"
  ],
  "next": "s05_031"
}
```

## 节点 `s05_031`

```json
{
  "node_id": "s05_031",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "如果玩家此时只抢伤害，山狼王会在濒死前撞断一处旧绳桩，释放更多蓝粉，场面恶化。"
  ],
  "next": "s05_032"
}
```

## 节点 `s05_032`

```json
{
  "node_id": "s05_032",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "如果玩家先处理绳桩，则会放弃一次高伤窗口，但降低全队后续压力。"
  ],
  "next": "s05_033"
}
```

## 节点 `s05_033`

```json
{
  "node_id": "s05_033",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "山狼王狂躁冲向旧猎道时，一块岩石被撞落。"
  ],
  "next": "s05_034"
}
```

## 节点 `s05_034`

```json
{
  "node_id": "s05_034",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "根据此前站位，天火冷魂或黄虎会被堵在侧坡。"
  ],
  "next": "s05_035"
}
```

## 节点 `s05_035`

```json
{
  "node_id": "s05_035",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "与此同时，藏宝图残片从天火冷魂包中滑出，落到另一侧泥地。"
  ],
  "next": "s05_036"
}
```

## 节点 `s05_036`

```json
{
  "node_id": "s05_036",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "风云黑虎立刻看见。"
  ],
  "next": "s05_037"
}
```

## 节点 `s05_037`

```json
{
  "node_id": "s05_037",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家此时只能优先做一件："
  ],
  "next": "s05_038"
}
```

## 节点 `s05_038`

```json
{
  "node_id": "s05_038",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "【救被困者】"
  ],
  "next": "s05_039"
}
```

## 节点 `s05_039`

```json
{
  "node_id": "s05_039",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "【压制狼王】"
  ],
  "next": "s05_040"
}
```

## 节点 `s05_040`

```json
{
  "node_id": "s05_040",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "【抢回藏宝图】"
  ],
  "next": "s05_041"
}
```

## 节点 `s05_041`

```json
{
  "node_id": "s05_041",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "【让岚音支援其中一项，自己处理另一项】"
  ],
  "next": "s05_042"
}
```

## 节点 `s05_042`

```json
{
  "node_id": "s05_042",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "这一步决定战后资源分配和关系评价。"
  ],
  "next": "s05_043"
}
```

## 节点 `s05_043`

```json
{
  "node_id": "s05_043",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若优先救人："
  ],
  "next": "s05_044"
}
```

## 节点 `s05_044`

```json
{
  "node_id": "s05_044",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "被困者安全，但狼王可能逃离或被风云组抢到部分掉落。"
  ],
  "next": "s05_045"
}
```

## 节点 `s05_045`

```json
{
  "node_id": "s05_045",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若优先狼王："
  ],
  "next": "s05_046"
}
```

## 节点 `s05_046`

```json
{
  "node_id": "s05_046",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "首领收益更稳定，但藏宝图可能被黑虎拿走。"
  ],
  "next": "s05_047"
}
```

## 节点 `s05_047`

```json
{
  "node_id": "s05_047",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若优先藏宝图："
  ],
  "next": "s05_048"
}
```

## 节点 `s05_048`

```json
{
  "node_id": "s05_048",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂认可玩家保住线索，但被困者会带伤脱险。"
  ],
  "next": "s05_049"
}
```

## 节点 `s05_049`

```json
{
  "node_id": "s05_049",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若合理利用岚音倾向："
  ],
  "next": "s05_050"
}
```

## 节点 `s05_050`

```json
{
  "node_id": "s05_050",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "可同时保住两项，但不能无代价获得全部三项。"
  ],
  "next": "s05_choice_3"
}
```

## 节点 `s05_choice_3_1_response`

```json
{
  "node_id": "s05_choice_3_1_response",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“先把人带出来。”",
    "若岚音为防守倾向：",
    "她直接切到被困者侧翼，玩家可专心挡狼。",
    "结果：救援成功率最高，但狼王更容易逃离。",
    "若岚音为进攻倾向：",
    "她会先打断狼王一次冲撞，再转身救援。",
    "结果：救人成功，但自身可能受轻伤。",
    "若玩家没有安排岚音且自己独自救援：",
    "需要承受一次狼群夹击。",
    "成功：救出目标。",
    "部分成功：两人都带伤脱离。",
    "失败：王五远程介入，进入战败续接前置。",
    "此路线不会自动判定“善良”，只明确玩家把人物安全放在当前收益前。"
  ],
  "next": "wolf_king_combat"
}
```

## 节点 `s05_choice_3_2_response`

```json
{
  "node_id": "s05_choice_3_2_response",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "玩家观察颈部金属残片后，可尝试打断束缚点。",
    "第一次直接砍金属：",
    "火星迸开，狼王因疼痛反扑。",
    "若先让岚音支援清除蓝粉，再处理残片：",
    "狼王狂躁明显下降。",
    "完全成功：狼王挣脱束缚后带群狼撤离。",
    "部分成功：狼王受伤逃走，狼径暂时不稳定。",
    "失败：残片被打进伤口，狼王彻底狂暴，转入击杀或战败版本。",
    "此路线的首领掉落最少，但会获得一块银黑材料残片作为调查线索。"
  ],
  "next": "wolf_king_combat"
}
```

## 节点 `s05_choice_3_3_response`

```json
{
  "node_id": "s05_choice_3_3_response",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月把注意力放在首领生命线上。",
    "风云石虎会立刻做出同样选择。",
    "最后阶段形成一次明确抢攻：",
    "若玩家之前保存了爆发技能，可抢到主要掉落；",
    "若没有，石虎抢到首击权；",
    "若双方同时抢攻，狼王会趁空档冲向侧坡，导致被困者伤势加重。",
    "此路线不是必然负面，但必须把“收益更高”与“其他目标更容易失去”同时演出来。"
  ],
  "next": "wolf_king_combat"
}
```

## 节点 `s05_choice_3_4_response`

```json
{
  "node_id": "s05_choice_3_4_response",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "玩家不追求击杀，而是优先切断诱饵绳、检查旧束缚点。",
    "第一处诱饵点被破坏后，狼群攻击性下降。",
    "第二处诱饵点附近能找到与黑铁银纹类似的碎屑。",
    "如果玩家连续两次调查成功：",
    "这只是调查物，不说明来源。",
    "代价：",
    "风云三人组更容易抢到首领收益。",
    "天火冷魂会评价：“你是真的能看着金币从面前走过去。”",
    "枫月：“我只是不想以后再被同一种东西追着咬。”",
    "天火冷魂：“这句话比金币贵。”"
  ],
  "next": "wolf_king_combat"
}
```

## 节点 `s05_choice_3`

```json
{
  "node_id": "s05_choice_3",
  "type": "choice",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice",
  "choices": [
    {
      "choice_id": "s05_choice_3_c1",
      "text": "优先救人",
      "intent": "优先救人",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s05_choice_3_1_response"
    },
    {
      "choice_id": "s05_choice_3_c2",
      "text": "优先控制狼王",
      "intent": "优先控制狼王",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s05_choice_3_2_response"
    },
    {
      "choice_id": "s05_choice_3_c3",
      "text": "优先抢首领掉落",
      "intent": "优先抢首领掉落",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s05_choice_3_3_response"
    },
    {
      "choice_id": "s05_choice_3_c4",
      "text": "追查束缚来源",
      "intent": "追查束缚来源",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s05_choice_3_4_response"
    }
  ],
  "next": "s05_052"
}
```

## 节点 `s05_052`

```json
{
  "node_id": "s05_052",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家每轮只指定："
  ],
  "next": "s05_053"
}
```

## 节点 `s05_053`

```json
{
  "node_id": "s05_053",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "进攻"
  ],
  "next": "s05_054"
}
```

## 节点 `s05_054`

```json
{
  "node_id": "s05_054",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "防守"
  ],
  "next": "s05_055"
}
```

## 节点 `s05_055`

```json
{
  "node_id": "s05_055",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "支援"
  ],
  "next": "s05_056"
}
```

## 节点 `s05_056`

```json
{
  "node_id": "s05_056",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "示例即时回应："
  ],
  "next": "s05_057"
}
```

## 节点 `s05_057`

```json
{
  "node_id": "s05_057",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家选进攻："
  ],
  "next": "s05_058"
}
```

## 节点 `s05_058`

```json
{
  "node_id": "s05_058",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "明白。你别站我箭路上。"
  ],
  "next": "s05_059"
}
```

## 节点 `s05_059`

```json
{
  "node_id": "s05_059",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家选防守："
  ],
  "next": "s05_060"
}
```

## 节点 `s05_060`

```json
{
  "node_id": "s05_060",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "我盯伤势最重的。你处理前面。"
  ],
  "next": "s05_061"
}
```

## 节点 `s05_061`

```json
{
  "node_id": "s05_061",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家选支援："
  ],
  "next": "s05_062"
}
```

## 节点 `s05_062`

```json
{
  "node_id": "s05_062",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "诱饵和绳索交给我。"
  ],
  "next": "s05_063"
}
```

## 节点 `s05_063`

```json
{
  "node_id": "s05_063",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "根据阶段随机触发，不重复："
  ],
  "next": "s05_064"
}
```

## 节点 `s05_064`

```json
{
  "node_id": "s05_064",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂受伤时："
  ],
  "next": "s05_065"
}
```

## 节点 `s05_065`

```json
{
  "node_id": "s05_065",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "我觉得这游戏对新手保护做得一般。"
  ],
  "next": "s05_066"
}
```

## 节点 `s05_066`

```json
{
  "node_id": "s05_066",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你不是新手。"
  ],
  "next": "s05_067"
}
```

## 节点 `s05_067`

```json
{
  "node_id": "s05_067",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "所以更糟。"
  ],
  "next": "s05_068"
}
```

## 节点 `s05_068`

```json
{
  "node_id": "s05_068",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "风云黄虎被狼扑倒时："
  ],
  "next": "s05_069"
}
```

## 节点 `s05_069`

```json
{
  "node_id": "s05_069",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "黄虎：“帮一把！”"
  ],
  "next": "s05_070"
}
```

## 节点 `s05_070`

```json
{
  "node_id": "s05_070",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若玩家救援："
  ],
  "next": "s05_071"
}
```

## 节点 `s05_071`

```json
{
  "node_id": "s05_071",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "黄虎：“欠你一次。”"
  ],
  "next": "s05_072"
}
```

## 节点 `s05_072`

```json
{
  "node_id": "s05_072",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若玩家不救："
  ],
  "next": "s05_073"
}
```

## 节点 `s05_073`

```json
{
  "node_id": "s05_073",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "石虎会救下黄虎。"
  ],
  "next": "s05_074"
}
```

## 节点 `s05_074`

```json
{
  "node_id": "s05_074",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "石虎：“记住。”"
  ],
  "next": "s05_075"
}
```

## 节点 `s05_075`

```json
{
  "node_id": "s05_075",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音生命较低时："
  ],
  "next": "s05_076"
}
```

## 节点 `s05_076`

```json
{
  "node_id": "s05_076",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "别看我，选目标。"
  ],
  "next": "s05_077"
}
```

## 节点 `s05_077`

```json
{
  "node_id": "s05_077",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若玩家改成防守倾向："
  ],
  "next": "s05_078"
}
```

## 节点 `s05_078`

```json
{
  "node_id": "s05_078",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "我还能走。"
  ],
  "next": "s05_079"
}
```

## 节点 `s05_079`

```json
{
  "node_id": "s05_079",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "能走和该不该继续扛是两回事。"
  ],
  "next": "s05_080"
}
```

## 节点 `s05_080`

```json
{
  "node_id": "s05_080",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "这是对她之前台词的轻微回收。"
  ],
  "next": "s05_081"
}
```

## 节点 `s05_081`

```json
{
  "node_id": "s05_081",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "王五远程支援时："
  ],
  "next": "s05_082"
}
```

## 节点 `s05_082`

```json
{
  "node_id": "s05_082",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "绳桩右边！"
  ],
  "next": "s05_083"
}
```

## 节点 `s05_083`

```json
{
  "node_id": "s05_083",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家若及时处理："
  ],
  "next": "s05_084"
}
```

## 节点 `s05_084`

```json
{
  "node_id": "s05_084",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "对，就是那儿。"
  ],
  "next": "s05_085"
}
```

## 节点 `s05_085`

```json
{
  "node_id": "s05_085",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若无视："
  ],
  "next": "s05_086"
}
```

## 节点 `s05_086`

```json
{
  "node_id": "s05_086",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "狼王下一阶段获得额外狂躁强化。"
  ],
  "next": "s05_087"
}
```

## 节点 `s05_087`

```json
{
  "node_id": "s05_087",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "wolf_battle_controlled"
  ],
  "next": "s05_088"
}
```

## 节点 `s05_088`

```json
{
  "node_id": "s05_088",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "wolf_battle_killed"
  ],
  "next": "s05_089"
}
```

## 节点 `s05_089`

```json
{
  "node_id": "s05_089",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "wolf_battle_escaped"
  ],
  "next": "s05_090"
}
```

## 节点 `s05_090`

```json
{
  "node_id": "s05_090",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "wolf_battle_defeat"
  ],
  "next": "s06_001"
}
```

## 节点 `s06_001`

```json
{
  "node_id": "s06_001",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若 defeat："
  ],
  "next": "s06_002",
  "effects": [
    {
      "key": "world.nv7.wolf_king_outcome",
      "op": "set",
      "value": "escaped"
    },
    {
      "key": "world.nv7.wangwu_injury_stage",
      "op": "set",
      "value": "medium"
    }
  ],
  "quest_actions": [
    {
      "action": "fail",
      "quest_id": "NV_MAIN_004",
      "continuation_id": "wolf_path_recovery"
    },
    {
      "action": "resume",
      "quest_id": "NV_MAIN_004"
    }
  ]
}
```

## 节点 `s06_002`

```json
{
  "node_id": "s06_002",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "一支箭从高处射断诱饵绳。"
  ],
  "next": "s06_003"
}
```

## 节点 `s06_003`

```json
{
  "node_id": "s06_003",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "狼群被突如其来的火花逼退。"
  ],
  "next": "s06_004"
}
```

## 节点 `s06_004`

```json
{
  "node_id": "s06_004",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "走！"
  ],
  "next": "s06_005"
}
```

## 节点 `s06_005`

```json
{
  "node_id": "s06_005",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音架住枫月。"
  ],
  "next": "s06_006"
}
```

## 节点 `s06_006`

```json
{
  "node_id": "s06_006",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "狼王……"
  ],
  "next": "s06_007"
}
```

## 节点 `s06_007`

```json
{
  "node_id": "s06_007",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "先把自己带走。"
  ],
  "next": "s06_008"
}
```

## 节点 `s06_008`

```json
{
  "node_id": "s06_008",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "风云石虎趁乱抢走一部分掉落。"
  ],
  "next": "s06_009"
}
```

## 节点 `s06_009`

```json
{
  "node_id": "s06_009",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂拖着伤腿跟上。"
  ],
  "next": "s06_010"
}
```

## 节点 `s06_010`

```json
{
  "node_id": "s06_010",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "王五最后撤离时被狼爪划伤。"
  ],
  "next": "s06_011"
}
```

## 节点 `s06_011`

```json
{
  "node_id": "s06_011",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "回到旧猎棚："
  ],
  "next": "s06_012"
}
```

## 节点 `s06_012`

```json
{
  "node_id": "s06_012",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "王五把血布按在肩上。"
  ],
  "next": "s06_013"
}
```

## 节点 `s06_013`

```json
{
  "node_id": "s06_013",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你的伤。"
  ],
  "next": "s06_014"
}
```

## 节点 `s06_014`

```json
{
  "node_id": "s06_014",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "死不了。"
  ],
  "next": "s06_015"
}
```

## 节点 `s06_015`

```json
{
  "node_id": "s06_015",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "苏芷不在场时，岚音直接说："
  ],
  "next": "s06_016"
}
```

## 节点 `s06_016`

```json
{
  "node_id": "s06_016",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "这句话一般都不可信。"
  ],
  "next": "s06_017"
}
```

## 节点 `s06_017`

```json
{
  "node_id": "s06_017",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_WANGWU",
  "expression": "hearty",
  "portrait_action": "show",
  "text": [
    "那你来包。"
  ],
  "next": "s06_018"
}
```

## 节点 `s06_018`

```json
{
  "node_id": "s06_018",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "失败长期结果："
  ],
  "next": "s06_019"
}
```

## 节点 `s06_019`

```json
{
  "node_id": "s06_019",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "GameState：world.nv7.wangwu_injury_stage = \"medium\""
  ],
  "next": "s06_020"
}
```

## 节点 `s06_020`

```json
{
  "node_id": "s06_020",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "狼王结果根据现场："
  ],
  "next": "s06_021"
}
```

## 节点 `s06_021`

```json
{
  "node_id": "s06_021",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "受伤逃离"
  ],
  "next": "s06_022"
}
```

## 节点 `s06_022`

```json
{
  "node_id": "s06_022",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "被风云组三人补杀"
  ],
  "next": "s06_023"
}
```

## 节点 `s06_023`

```json
{
  "node_id": "s06_023",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "暂时控制后逃离"
  ],
  "next": "s06_024"
}
```

## 节点 `s06_024`

```json
{
  "node_id": "s06_024",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "不可读档式重置本场世界结果。"
  ],
  "next": "s07_001"
}
```

## 节点 `s07_001`

```json
{
  "node_id": "s07_001",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂把藏宝图残片摊在桌上。"
  ],
  "next": "s07_002"
}
```

## 节点 `s07_002`

```json
{
  "node_id": "s07_002",
  "type": "dialogue",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "我先说。"
  ],
  "next": "s07_003"
}
```

## 节点 `s07_003`

```json
{
  "node_id": "s07_003",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“这东西不是谁砍最后一下就归谁。”"
  ],
  "next": "s07_004"
}
```

## 节点 `s07_004`

```json
{
  "node_id": "s07_004",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“没岚音带路，我找不到。”"
  ],
  "next": "s07_005"
}
```

## 节点 `s07_005`

```json
{
  "node_id": "s07_005",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“没人救我，我现在还在石头上。”"
  ],
  "next": "s07_006"
}
```

## 节点 `s07_006`

```json
{
  "node_id": "s07_006",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "黑虎：“所以？”"
  ],
  "next": "s07_007"
}
```

## 节点 `s07_007`

```json
{
  "node_id": "s07_007",
  "type": "dialogue",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "所以你先闭嘴。"
  ],
  "next": "s07_choice_4"
}
```

## 节点 `s07_choice_4_1_response`

```json
{
  "node_id": "s07_choice_4_1_response",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“图可以有保管人，坐标所有参与者共享。”",
    "岚音：“至少不会因为一张纸再打一场。”"
  ],
  "next": "s08_001"
}
```

## 节点 `s07_choice_4_2_response`

```json
{
  "node_id": "s07_choice_4_2_response",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“谁做了什么，按贡献算。”",
    "石虎：“怎么算？”",
    "枫月：“先把救人也算进去。”",
    "若玩家此前优先救人，关系结果更好。"
  ],
  "next": "s08_001"
}
```

## 节点 `s07_choice_4_3_response`

```json
{
  "node_id": "s07_choice_4_3_response",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "天火冷魂：“你保管？”",
    "枫月：“我不藏坐标。”",
    "石虎：“最好是。”"
  ],
  "next": "s08_001"
}
```

## 节点 `s07_choice_4_4_response`

```json
{
  "node_id": "s07_choice_4_4_response",
  "type": "narrative",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“本来就是你的线索。”",
    "天火冷魂：“你这么讲道理，我有点不习惯。”",
    "枫月：“可以还我。”",
    "天火冷魂：“当我没说。”",
    "无论方式，InventoryManager 只保留一份正式任务物：",
    "proposed_item_id:quest_treasure_map_fragment",
    "所有权由 QuestManager 根据选项确定，后续任务通过任务共享权限读取，不复制多份逻辑物品。"
  ],
  "next": "s08_001"
}
```

## 节点 `s07_choice_4`

```json
{
  "node_id": "s07_choice_4",
  "type": "choice",
  "scene_id": "s07",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_choice",
  "choices": [
    {
      "choice_id": "s07_choice_4_d1",
      "text": "平均共享信息",
      "intent": "平均共享信息",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s07_choice_4_1_response"
    },
    {
      "choice_id": "s07_choice_4_d2",
      "text": "按贡献分配",
      "intent": "按贡献分配",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s07_choice_4_2_response"
    },
    {
      "choice_id": "s07_choice_4_d3",
      "text": "枫月保管，公开坐标",
      "intent": "枫月保管，公开坐标",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s07_choice_4_3_response"
    },
    {
      "choice_id": "s07_choice_4_d4",
      "text": "交给天火冷魂",
      "intent": "交给天火冷魂",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s07_choice_4_4_response"
    }
  ],
  "next": "s08_001"
}
```

## 节点 `s08_001`

```json
{
  "node_id": "s08_001",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若 rel_lanyin_fengyue 达到中等亲近："
  ],
  "next": "s08_002"
}
```

## 节点 `s08_002`

```json
{
  "node_id": "s08_002",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "众人散去后，岚音叫住枫月。"
  ],
  "next": "s08_003"
}
```

## 节点 `s08_003`

```json
{
  "node_id": "s08_003",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "手。"
  ],
  "next": "s08_004"
}
```

## 节点 `s08_004`

```json
{
  "node_id": "s08_004",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "什么？"
  ],
  "next": "s08_005"
}
```

## 节点 `s08_005`

```json
{
  "node_id": "s08_005",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "伸过来。"
  ],
  "next": "s08_006"
}
```

## 节点 `s08_006`

```json
{
  "node_id": "s08_006",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "她重新绑紧枫月松开的护腕。"
  ],
  "next": "s08_007"
}
```

## 节点 `s08_007`

```json
{
  "node_id": "s08_007",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "我自己可以。"
  ],
  "next": "s08_008"
}
```

## 节点 `s08_008`

```json
{
  "node_id": "s08_008",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "可以和做得好是两回事。"
  ],
  "next": "s08_009"
}
```

## 节点 `s08_009`

```json
{
  "node_id": "s08_009",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "这句话韩石也会喜欢。"
  ],
  "next": "s08_010"
}
```

## 节点 `s08_010`

```json
{
  "node_id": "s08_010",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "那你下次让他给你绑。"
  ],
  "next": "s08_011"
}
```

## 节点 `s08_011`

```json
{
  "node_id": "s08_011",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "算了。"
  ],
  "next": "s08_012"
}
```

## 节点 `s08_012`

```json
{
  "node_id": "s08_012",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音抬眼。"
  ],
  "next": "s08_013"
}
```

## 节点 `s08_013`

```json
{
  "node_id": "s08_013",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "为什么？"
  ],
  "next": "s08_014"
}
```

## 节点 `s08_014`

```json
{
  "node_id": "s08_014",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "他手劲看起来会把骨头一起固定。"
  ],
  "next": "s08_015"
}
```

## 节点 `s08_015`

```json
{
  "node_id": "s08_015",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音笑了一下，很快收起。"
  ],
  "next": "s08_016"
}
```

## 节点 `s08_016`

```json
{
  "node_id": "s08_016",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "若关系较低："
  ],
  "next": "s08_017"
}
```

## 节点 `s08_017`

```json
{
  "node_id": "s08_017",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音只把备用绑带递给他。"
  ],
  "next": "s08_018"
}
```

## 节点 `s08_018`

```json
{
  "node_id": "s08_018",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "松了。"
  ],
  "next": "s08_019"
}
```

## 节点 `s08_019`

```json
{
  "node_id": "s08_019",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "谢谢。"
  ],
  "next": "s08_020"
}
```

## 节点 `s08_020`

```json
{
  "node_id": "s08_020",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "别误会。路上掉下来我还得捡你。"
  ],
  "next": "s08_021"
}
```

## 节点 `s08_021`

```json
{
  "node_id": "s08_021",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "藏宝图最终指向废弃旧补给站。"
  ],
  "next": "s08_022"
}
```

## 节点 `s08_022`

```json
{
  "node_id": "s08_022",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "地下应该有东西。"
  ],
  "next": "s08_023"
}
```

## 节点 `s08_023`

```json
{
  "node_id": "s08_023",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "宝藏？"
  ],
  "next": "s08_024"
}
```

## 节点 `s08_024`

```json
{
  "node_id": "s08_024",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "至少地图这么认为。"
  ],
  "next": "s08_025"
}
```

## 节点 `s08_025`

```json
{
  "node_id": "s08_025",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "地图不会认为。"
  ],
  "next": "s08_026"
}
```

## 节点 `s08_026`

```json
{
  "node_id": "s08_026",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "你们本地人讲话都这么认真？"
  ],
  "next": "s08_027"
}
```

## 节点 `s08_027`

```json
{
  "node_id": "s08_027",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "只对容易死的人。"
  ],
  "next": "s08_028"
}
```

## 节点 `s08_028`

```json
{
  "node_id": "s08_028",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "GameState 结算："
  ],
  "next": "s08_029"
}
```

## 节点 `s08_029`

```json
{
  "node_id": "s08_029",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "world.nv7.wolf_king_outcome"
  ],
  "next": "s08_030"
}
```

## 节点 `s08_030`

```json
{
  "node_id": "s08_030",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "world.nv7.wangwu_injury_stage"
  ],
  "next": "s08_031"
}
```

## 节点 `s08_031`

```json
{
  "node_id": "s08_031",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "world.nv7.fengyun_relation_stage"
  ],
  "next": "s08_032"
}
```

## 节点 `s08_032`

```json
{
  "node_id": "s08_032",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "world.nv7.adventurers_trapped_confirmed = true"
  ],
  "next": "s08_033"
}
```

## 节点 `s08_033`

```json
{
  "node_id": "s08_033",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "王五未伤："
  ],
  "next": "s08_034"
}
```

## 节点 `s08_034`

```json
{
  "node_id": "s08_034",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“狼径的问题没解决，只是暂时压住。”"
  ],
  "next": "s08_035"
}
```

## 节点 `s08_035`

```json
{
  "node_id": "s08_035",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "王五受伤："
  ],
  "next": "s08_036"
}
```

## 节点 `s08_036`

```json
{
  "node_id": "s08_036",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“别因为我受伤就停。伤是结果，不是命令。”"
  ],
  "next": "s08_037"
}
```

## 节点 `s08_037`

```json
{
  "node_id": "s08_037",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "天火冷魂："
  ],
  "next": "s08_038"
}
```

## 节点 `s08_038`

```json
{
  "node_id": "s08_038",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“藏宝洞见。”"
  ],
  "next": "s08_039"
}
```

## 节点 `s08_039`

```json
{
  "node_id": "s08_039",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你确定不是第二块困住你的高石？"
  ],
  "next": "s08_040"
}
```

## 节点 `s08_040`

```json
{
  "node_id": "s08_040",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_TIANHUOLENGHUN",
  "expression": "confident",
  "portrait_action": "show",
  "text": [
    "这次我带绳。"
  ],
  "next": "s08_041"
}
```

## 节点 `s08_041`

```json
{
  "node_id": "s08_041",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "风云石虎根据关系："
  ],
  "next": "s08_042"
}
```

## 节点 `s08_042`

```json
{
  "node_id": "s08_042",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "敌对：“洞里见。图是谁的，到时候再算。”"
  ],
  "next": "s08_043"
}
```

## 节点 `s08_043`

```json
{
  "node_id": "s08_043",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "警惕：“先说好，找到东西别装没看见。”"
  ],
  "next": "s08_044"
}
```

## 节点 `s08_044`

```json
{
  "node_id": "s08_044",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "合作：“地下情况不明，进去以后先活着。”"
  ],
  "next": "s08_045"
}
```

## 节点 `s08_045`

```json
{
  "node_id": "s08_045",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "岚音："
  ],
  "next": "s08_046"
}
```

## 节点 `s08_046`

```json
{
  "node_id": "s08_046",
  "type": "narrative",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_narrative",
  "text": [
    "“回村补东西。”"
  ],
  "next": "s08_047"
}
```

## 节点 `s08_047`

```json
{
  "node_id": "s08_047",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你也去？"
  ],
  "next": "s08_048"
}
```

## 节点 `s08_048`

```json
{
  "node_id": "s08_048",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "我不信那张图。"
  ],
  "next": "s08_049"
}
```

## 节点 `s08_049`

```json
{
  "node_id": "s08_049",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "所以？"
  ],
  "next": "s08_050"
}
```

## 节点 `s08_050`

```json
{
  "node_id": "s08_050",
  "type": "dialogue",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_LANYIN",
  "expression": "neutral",
  "portrait_action": "show",
  "text": [
    "所以我更得去。"
  ],
  "quest_actions": [
    {
      "action": "update_objective",
      "quest_id": "NV_MAIN_004",
      "objective_id": "resolve_wolf_event",
      "update": {
        "value": true
      }
    }
  ],
  "next": "story_complete"
}
```

## 节点 `story_complete`

```json
{
  "node_id": "story_complete",
  "type": "complete",
  "scene_id": "s08",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "r1_story_complete",
  "terminal": true,
  "outcome": "nv_main_004_complete"
}
```

## 节点 `wolf_king_combat`

```json
{
  "node_id": "wolf_king_combat",
  "type": "combat",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "wolf_king_three_party_battle",
  "combat_ref": "NV7_COMBAT_WOLF_KING",
  "next_on_win": "wolf_king_success",
  "next_on_loss": "s06_001"
}
```

## 节点 `wolf_king_success`

```json
{
  "node_id": "wolf_king_success",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_WOLF_PATH",
  "purpose": "combat_result",
  "text": [
    "山狼王的攻势被控制，众人得以撤向旧猎棚。"
  ],
  "effects": [
    {
      "key": "world.nv7.wolf_king_outcome",
      "op": "set",
      "value": "controlled"
    }
  ],
  "next": "s07_001"
}
```
