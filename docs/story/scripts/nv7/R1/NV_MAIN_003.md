# TASK NV_MAIN_003《兔王不该出现》

## META

```story-meta
{
  "quest": {
    "schema_version": "1.5.0",
    "quest_id": "NV_MAIN_003",
    "content_status": "complete_script",
    "title": "兔王不该出现",
    "region_id": "NV7",
    "category": "main",
    "source_chapters": [
      "5",
      "6"
    ],
    "source_refs": [
      "reviewed-package:R1.1/03_NV_MAIN_003_兔王不该出现_COMPLETE_SCRIPT.md"
    ],
    "design": {
      "purpose": "第七新手村R1正式接入",
      "theme": "被困世界中的求证与协作",
      "emotion": "异常、试探、行动",
      "source": "审核通过的R1.1完整剧本包",
      "adaptation": "机械结构化，不改写核心台词",
      "conflict": "玩家在真实风险中判断行动",
      "mechanic": "对话、选择、任务与战斗引用",
      "start": "药田不是战场",
      "end": "岚音正式加入阶段同行",
      "feedback": "保留任务后回访"
    },
    "prerequisites": [],
    "mutual_exclusions": [],
    "trigger": {
      "method": "story_chain",
      "location_id": "NV7_LOC_APOTHECARY",
      "conditions": [],
      "opening_presentation": {}
    },
    "scenes": [
      {
        "scene_id": "s01",
        "title": "药田不是战场",
        "entry_nodes": [
          "s01_001"
        ],
        "exit_nodes": [
          "s01_024"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_LANYIN",
          "NV7_NPC_SUZHI"
        ],
        "objective": "药田不是战场",
        "optional_interactions": []
      },
      {
        "scene_id": "s02",
        "title": "限时调查",
        "entry_nodes": [
          "s02_investigation_choice"
        ],
        "exit_nodes": [
          "s02_027"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_LANYIN",
          "NV7_NPC_SUZHI"
        ],
        "objective": "限时调查",
        "optional_interactions": []
      },
      {
        "scene_id": "s03",
        "title": "兔王出现",
        "entry_nodes": [
          "s03_001"
        ],
        "exit_nodes": [
          "s03_choice_1"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_LANYIN",
          "NV7_NPC_SUZHI"
        ],
        "objective": "兔王出现",
        "optional_interactions": []
      },
      {
        "scene_id": "s04",
        "title": "失败续接",
        "entry_nodes": [
          "s04_001"
        ],
        "exit_nodes": [
          "s04_022"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_LANYIN",
          "NV7_NPC_SUZHI"
        ],
        "objective": "失败续接",
        "optional_interactions": []
      },
      {
        "scene_id": "s05",
        "title": "岚音正式加入阶段同行",
        "entry_nodes": [
          "s05_001"
        ],
        "exit_nodes": [
          "s05_029"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_LANYIN",
          "NV7_NPC_SUZHI"
        ],
        "objective": "岚音正式加入阶段同行",
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
        "node_id": "s05_001"
      }
    ],
    "rewards": [
      {
        "type": "signal_only",
        "reward_id": "NV_MAIN_003_REWARD"
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
      "notes": "R1.1审核包机械结构化；迁移映射见生成报告。"
    },
    "runtime": {
      "status_state_key": "quest.nv_main_003.status",
      "reward_granted_state_key": "quest.nv_main_003.reward_granted",
      "availability": {
        "all": [
          {
            "kind": "quest",
            "quest_id": "NV_MAIN_002",
            "op": "in",
            "value": [
              "qualified",
              "completed"
            ]
          }
        ],
        "any": []
      },
      "objectives": [
        {
          "objective_id": "resolve_rabbit_event",
          "type": "boolean",
          "required": true,
          "progress_state_key": "quest.nv_main_003.objective.resolve_rabbit_event",
          "target": true
        }
      ],
      "completion_mode": "automatic",
      "failure": {
        "continuation_state_key": "quest.nv_main_003.continuation",
        "allowed_continuations": [
          "none",
          "apothecary_recovery"
        ],
        "resume_from_failed": "active",
        "resume_from_suspended": "active",
        "reopen_allowed": true
      }
    },
    "allowed_loops": [],
    "test_cases": [
      {
        "test_id": "nv_main_003_start",
        "initial_state": {},
        "steps": [
          "s01_001"
        ],
        "expected": [
          "story_started"
        ]
      },
      {
        "test_id": "nv_main_003_route",
        "initial_state": {},
        "steps": [
          "s01_001"
        ],
        "expected": [
          "choice_or_dialogue"
        ]
      },
      {
        "test_id": "nv_main_003_complete",
        "initial_state": {},
        "steps": [
          "s01_001"
        ],
        "expected": [
          "story_complete"
        ]
      }
    ]
  },
  "baseline": {
    "min_visible_text_chars": 2500,
    "min_nodes": 6,
    "min_dialogue_nodes": 20,
    "min_choice_nodes": 2,
    "min_terminal_nodes": 1,
    "required_node_ids": [
      "s01_001",
      "story_complete"
    ]
  },
  "ownership": {
    "conditions": "GameState",
    "effects": "GameState",
    "quest_actions": "QuestManager",
    "item_rewards": "InventoryManager",
    "combat_id": "CombatRunner",
    "relationship_actions": "RelationshipManager",
    "expression": "MainUI",
    "gesture": "MainUI",
    "portrait_action": "MainUI",
    "camera": "MainUI",
    "delivery": "MainUI"
  }
}
```
## SCENE s01：药田不是战场

```story-node
{"node_id":"s01_001","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["北药田已经乱成一团。"],"next":"s01_002","quest_actions":[{"action":"activate","quest_id":"NV_MAIN_003"}],"effects":[{"key":"world.nv7.rabbit_event_started","op":"set","value":true}],"foreshadowing_refs":["LIVE_CREATURE_PURCHASE","SILVER_BLACK_SYSTEM_MATERIAL","LANYIN_CHARACTER_ARC"]}
```

```story-node
{"node_id":"s01_002","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["几十只嘟嘟兔在药垄之间乱窜，木架被撞倒，藤蔓拖在泥里。村民拿着竹竿驱赶，却越赶越乱。"],"next":"s01_003"}
```

```story-node
{"node_id":"s01_003","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["枫月伸手摸向武器。"],"next":"s01_004"}
```

```story-node
{"node_id":"s01_004","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["一个声音从右侧传来。"],"next":"s01_005"}
```

```story-node
{"node_id":"s01_005","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["先别拔。"],"next":"s01_006"}
```

```story-node
{"node_id":"s01_006","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["岚音蹲在破篱笆旁，用两指捻起蓝粉"],"next":"s01_007"}
```

```story-node
{"node_id":"s01_007","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["理由？"],"next":"s01_008"}
```

```story-node
{"node_id":"s01_008","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["它们没在追人。"],"next":"s01_009"}
```

```story-node
{"node_id":"s01_009","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["枫月看去。"],"next":"s01_010"}
```

```story-node
{"node_id":"s01_010","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["一只嘟嘟兔从村民脚边窜过，宁愿撞翻木盆，也没有回头咬人。"],"next":"s01_011"}
```

```story-node
{"node_id":"s01_011","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["在逃。"],"next":"s01_012"}
```

```story-node
{"node_id":"s01_012","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["对。"],"next":"s01_013"}
```

```story-node
{"node_id":"s01_013","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["苏芷从另一边赶来。"],"next":"s01_014"}
```

```story-node
{"node_id":"s01_014","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["东侧篱笆拆开！"],"next":"s01_015"}
```

```story-node
{"node_id":"s01_015","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["别把它们逼回药田中央！"],"next":"s01_016"}
```

```story-node
{"node_id":"s01_016","type":"narrative","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["岚音抬头看枫月。"],"next":"s01_017"}
```

```story-node
{"node_id":"s01_017","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["会看痕迹吗？"],"next":"s01_018"}
```

```story-node
{"node_id":"s01_018","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["刚学。"],"next":"s01_019"}
```

```story-node
{"node_id":"s01_019","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["够了。"],"next":"s01_020"}
```

```story-node
{"node_id":"s01_020","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["不会的人最危险的不是不会。"],"next":"s01_021"}
```

```story-node
{"node_id":"s01_021","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["是觉得自己已经会。"],"next":"s01_022"}
```

```story-node
{"node_id":"s01_022","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["你每次认识新人都先打击一下？"],"next":"s01_023"}
```

```story-node
{"node_id":"s01_023","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["不。"],"next":"s01_024"}
```

```story-node
{"node_id":"s01_024","type":"dialogue","scene_id":"s01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["有些不用。"],"next":"s02_investigation_choice"}
```

## SCENE s02：限时调查

```story-node
{"node_id":"s02_001","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["玩家拥有三次主要行动机会，第四次行动后兔王必然出现。"],"next":"s02_002"}
```

```story-node
{"node_id":"s02_002","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["可调查目标："],"next":"s02_003"}
```

```story-node
{"node_id":"s02_003","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["枫月扒开泥土，发现断裂铁齿。"],"next":"s02_004"}
```

```story-node
{"node_id":"s02_004","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["不是村里的夹子。"],"next":"s02_005"}
```

```story-node
{"node_id":"s02_005","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["你这么确定？"],"next":"s02_006"}
```

```story-node
{"node_id":"s02_006","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["村里做夹子的人舍不得用这种好钢。"],"next":"s02_007"}
```

```story-node
{"node_id":"s02_007","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若完成韩石委托："],"next":"s02_008"}
```

```story-node
{"node_id":"s02_008","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["韩石那边也见过银纹。"],"next":"s02_009"}
```

```story-node
{"node_id":"s02_009","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["那就把它当一条线，不要当答案。"],"next":"s02_010"}
```

```story-node
{"node_id":"s02_010","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["靴印绕开药垄，明显有人熟悉地形。"],"next":"s02_011"}
```

```story-node
{"node_id":"s02_011","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["兔子不会穿靴子。"],"next":"s02_012"}
```

```story-node
{"node_id":"s02_012","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["这句判断很稳。"],"next":"s02_013"}
```

```story-node
{"node_id":"s02_013","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若完成苏芷委托，直接识别。"],"next":"s02_014"}
```

```story-node
{"node_id":"s02_014","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["同一种粉。"],"next":"s02_015"}
```

```story-node
{"node_id":"s02_015","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["岚音闻了闻，立刻偏开脸。"],"next":"s02_016"}
```

```story-node
{"node_id":"s02_016","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["味道太重。有人从北坡一路撒到这里。"],"next":"s02_017"}
```

```story-node
{"node_id":"s02_017","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["玩家协助苏芷搬走易损药材。"],"next":"s02_018"}
```

```story-node
{"node_id":"s02_018","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["你去查痕迹，这里我能处理。"],"next":"s02_019"}
```

```story-node
{"node_id":"s02_019","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["玩家可坚持留下。"],"next":"s02_020"}
```

```story-node
{"node_id":"s02_020","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若留下，减少药田损失，但少拿一条证据。"],"next":"s02_021"}
```

```story-node
{"node_id":"s02_021","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["建立兔群撤离通道。"],"next":"s02_022"}
```

```story-node
{"node_id":"s02_022","type":"dialogue","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["这会让后面容易很多。"],"next":"s02_023"}
```

```story-node
{"node_id":"s02_023","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["后续保护路线难度降低。"],"next":"s02_024"}
```

```story-node
{"node_id":"s02_024","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["可远远看见灌渠边有人离开。"],"next":"s02_025"}
```

```story-node
{"node_id":"s02_025","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若选择追，提前进入捕兽者支线，但兔王现场处理空间变小。"],"next":"s02_026"}
```

```story-node
{"node_id":"s02_026","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["至少取得“蓝粉+人造陷阱”或“蓝粉+靴印”两项后，形成确证："],"next":"s02_027"}
```

```story-node
{"node_id":"s02_027","type":"narrative","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["GameState：world.nv7.live_capture_evidence = \"confirmed_local_operation\""],"next":"s03_001"}
```

## SCENE s03：兔王出现

```story-node
{"node_id":"s03_001","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["[BG_SHAKE: 中]"],"next":"s03_002"}
```

```story-node
{"node_id":"s03_002","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["药田中央隆起。"],"next":"s03_003"}
```

```story-node
{"node_id":"s03_003","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["一只体型远超普通嘟嘟兔的白色巨兔撞破木架。耳尖有金色纹路。"],"next":"s03_004"}
```

```story-node
{"node_id":"s03_004","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["【稀有首领：金纹嘟嘟兔王】"],"next":"s03_005"}
```

```story-node
{"node_id":"s03_005","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["【高价值掉落】"],"next":"s03_006"}
```

```story-node
{"node_id":"s03_006","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["系统金光刚亮，兔王已经冲出去。"],"next":"s03_007"}
```

```story-node
{"node_id":"s03_007","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["不是冲向枫月。"],"next":"s03_008"}
```

```story-node
{"node_id":"s03_008","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["它撞开一根倒木，把压在下面的小兔拱了出来。"],"next":"s03_009"}
```

```story-node
{"node_id":"s03_009","type":"dialogue","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["……"],"next":"s03_010"}
```

```story-node
{"node_id":"s03_010","type":"dialogue","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["系统刚才是不是给你写了高价值？"],"next":"s03_011"}
```

```story-node
{"node_id":"s03_011","type":"dialogue","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["写了。"],"next":"s03_012"}
```

```story-node
{"node_id":"s03_012","type":"dialogue","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["那现在再看一眼。"],"next":"s03_013"}
```

```story-node
{"node_id":"s03_013","type":"dialogue","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["有人在等它被逼出来。"],"next":"s03_014"}
```

```story-node
{"node_id":"s03_014","type":"dialogue","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["对。"],"next":"s03_choice_1"}
```

```story-node
{"node_id":"s03_choice_1_1_response","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["进入“撤离战”。","进入“撤离战”，但表现为三个明确阶段，不要求逐回合写死对白。","东侧篱笆刚拆开，一张隐藏捕网从泥里弹起，正好封住缺口。","村民甲：“怎么还有网！”","岚音：“不是刚放的。早埋在这里了。”","兔群重新受惊，开始往药田中央挤。兔王第一次冲撞不是攻击玩家，而是撞向捕网。","玩家此时必须在三个动作中选一个主要处理：","【砍断网绳】：最快，但靠近兔王冲撞线；","【引导兔群后退】：降低踩踏损失，但网仍在；","【让岚音处理陷阱】：玩家转去挡住翻倒木架。","若玩家什么都只顾攻击兔王，第一阶段结束时一处药垄被踩毁，苏芷在远处喊：","苏芷：“别追着它打！先让路出来！”","捕网一角断开后，一只幼兔却卡在倒塌木架下面。","兔王立刻改变方向，撞开靠近它的人。","岚音：“它不是冲你。”","枫月：“它想去那边。”","玩家可：","【抬木架】直接救幼兔；","【防御顶住兔王】给岚音救援时间；","【攻击逼退兔王】获得更安全空间，但兔王敌意明显上升。","若第一次抬架失败：","木架比预想更重，枫月手臂被压住。","岚音会立刻支援。","岚音：“别硬扛，往左抬！”","这是“第一次处理失败”的完整演出，不直接判定任务失败，只增加下一阶段压力。","若玩家选择防御：","兔王撞击后短暂停住。","系统提示防御减伤。","岚音趁机拖出幼兔。","岚音：“这次挡得对。”","幼兔获救后，远处有人拉动第二根诱饵绳。","蓝色粉末袋在风里炸开。","兔王进入短暂狂躁，开始无差别冲撞。","此时伙伴倾向正式开放：","进攻：岚音优先射断诱饵绳；","防守：岚音保护村民和幼兔；","支援：岚音处理粉末袋和剩余捕夹。","玩家需要完成“让撤离口重新可用”这一最终目标。","完全成功：","捕网解除","幼兔获救","撤离口开放","药田只受轻度损失","部分成功：","兔群能撤离","但药田或村民出现额外损失","兔王可能带伤","失败：","枫月失去战斗能力，进入药棚续接","世界保持恶化后的状态，不重置","rabbit_event_protect_success / rabbit_event_protect_partial / rabbit_event_defeat","成功后，兔王停在缺口前回头看了一眼，随后带着兔群钻入林地。","一张旧面罩挂在捕网上。","岚音取下，拍掉泥。","岚音：“拿着。”","枫月：“兔王掉的？”","岚音：“不是。”","岚音：“它活着。”","岚音：“这是捕兽人丢的。”","GameState：","world.nv7.rabbit_king_outcome = \"alive\"","world.nv7.rabbit_herd_outcome = \"escaped\""],"next":"rabbit_route_1_combat","effects":[{"key":"world.nv7.rabbit_king_outcome","op":"set","value":"alive"},{"key":"world.nv7.rabbit_herd_outcome","op":"set","value":"escaped"},{"key":"world.nv7.live_capture_evidence","op":"set","value":"none"}]}
```

```story-node
{"node_id":"s03_choice_1_2_response","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["枫月：“人比兔子更会回答问题。”","岚音看向仍在混乱中的药田。","岚音：“去。”","岚音：“这里我顶一会儿。”","枫月沿着靴印追出药田。前方的人影背着空笼，跑得并不快，却不断把蓝色粉末撒进身后。","第一次障碍是一段被粉末刺激后躁动的小型兽群。","玩家可：","【绕行】耗时最少，但失去观察证据；","【用水冲开粉末】消耗携带水，兽群自行散开；","【强行穿过】进入短战斗，耗时增加。","第二次障碍是灌渠木桥。","捕兽者把桥板踢断一块。","若玩家此前在三份委托中表现出良好观察：","可发现旁边旧灌木根系能承担一次跨越，直接追上。","否则只能选择：","跳过缺口，成功则继续；","走下灌渠绕路，稳定但耗时。","最终在废弃水车旁追上受雇捕兽者。","捕兽者：“让开！这和你没关系！”","枫月：“你把一群兔子赶进村里之后，这句话过期了。”","捕兽者抽出短刀，却不断回头看自己脚边的铁箱。","玩家第一次可以误判目标：","若直接攻击，捕兽者会趁后退时点燃账册一角。","若先观察，系统提示：","【对方注意力集中在铁箱与火种，不像准备死战。】","随后出现三种处理：","1.【制服】","枫月逼近，打掉短刀。","捕兽者试图伸手摸火种。","玩家需追加一次【阻止点火】。","成功：完整账页。","部分成功：上半册烧毁，保留下半册。","2.【抢账册】","枫月直接扑向铁箱。","捕兽者趁机逃走。","结果：取得半册账页，但失去口供机会。","3.【先解除活体笼机关】","铁箱旁其实还有两只被压缩笼困住的小兔。","解除机关时，捕兽者开始点火。","岚音若信任足够高，会从远处赶来一箭射落火种。","若岚音未及时赶到，则只能保住部分账页。","账册信息：","【异常活体收购】","【兔类 / 狼类 / 大型兽类】","【非自然强化者优先】","【交付地：未记录】","返回药田时根据耗时：","快：还能参与兔王最终撤离；","中：兔王带伤逃走，岚音保住大部分幼兔；","慢：现场已结束，村民只完成最低驱散，药田损失扩大。","GameState：world.nv7.live_capture_evidence = \"ledger_partial\" 或 \"ledger_full\""],"next":"rabbit_route_2_combat","effects":[{"key":"world.nv7.rabbit_king_outcome","op":"set","value":"alive"},{"key":"world.nv7.rabbit_herd_outcome","op":"set","value":"scattered"},{"key":"world.nv7.live_capture_evidence","op":"set","value":"ledger_partial"}]}
```

```story-node
{"node_id":"s03_choice_1_3_response","type":"narrative","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["枫月拔出武器。","岚音看了他一眼。","岚音：“你确定？”","玩家确认后进入首领战。","枫月：“我需要先活下来，也需要装备。”","岚音：“可以。”","岚音：“那就别骗自己说这里只有这一条路。”","战斗中关键演出：","第一阶段兔王仍会优先保护幼兔，只有玩家持续攻击后才真正转向枫月。","第二阶段兔王利用倒塌木架改变冲撞路线，玩家可以观察并提前防御。","若玩家攻击到低生命阶段，岚音会再次确认：","岚音：“现在停，还来得及让它走。”","玩家可继续，也可改为驱离路线。","胜利后，岚音不立即评价。","苏芷先处理药田。顾长川确认兔群已经散开后，岚音才在村外问：","岚音：“为什么杀它？”","玩家回应：","【坦白】“我需要收益，也需要装备。”","岚音：“至少你知道自己拿了什么，也知道为什么。”","【判断风险】“我不确定放它走会不会再伤人。”","若此前兔王已有主动伤人证据：trust +0","若没有证据：岚音只回“那是你的判断”，不加不扣。","【伪装正当】“我是为了村子，没别的选择。”","若现场明确存在保护路线：","岚音：“有。”","岚音：“你只是没选。”","proposed_item_id:eq_mask_dudu_rabbit x1","兔王材料若干","额外新手币","GameState：","world.nv7.rabbit_king_outcome = \"dead\"","world.nv7.rabbit_herd_outcome = \"scattered\"","若坦白“我需要收益/装备”：respect +1，trust +0","若说明“我判断它继续留在这里风险更大”且现场证据支持：trust +0，tension +0","若明知存在其他路线却谎称“我只能为了村子杀它”：trust -1，tension +1","苏芷事后查看被踩坏的地。","苏芷：“药田接下来会少一批松土的兔子。”","枫月：“药价会上涨。”","苏芷：“会。”","苏芷：“不是为了惩罚你。”","苏芷：“是因为事情真的发生过。”"],"next":"rabbit_route_3_combat","effects":[{"key":"world.nv7.rabbit_king_outcome","op":"set","value":"dead"},{"key":"world.nv7.rabbit_herd_outcome","op":"set","value":"displaced"},{"key":"world.nv7.live_capture_evidence","op":"set","value":"none"}]}
```

```story-node
{"node_id":"s03_choice_1","type":"choice","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice","choices":[{"choice_id":"s03_choice_1_a1","text":"先救兔群","intent":"先救兔群","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"s03_choice_1_1_response"},{"choice_id":"s03_choice_1_a2","text":"追捕兽者","intent":"追捕兽者","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"s03_choice_1_2_response"},{"choice_id":"s03_choice_1_a3","text":"直接猎杀兔王","intent":"直接猎杀兔王","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"s03_choice_1_3_response"}],"next":"s04_001"}
```

## SCENE s04：失败续接

```story-node
{"node_id":"s04_001","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["若 CombatRunner 返回 defeat："],"next":"s04_002","effects":[{"key":"world.nv7.rabbit_king_outcome","op":"set","value":"injured"},{"key":"world.nv7.rabbit_herd_outcome","op":"set","value":"scattered"}],"quest_actions":[{"action":"fail","quest_id":"NV_MAIN_003","continuation_id":"apothecary_recovery"},{"action":"resume","quest_id":"NV_MAIN_003"}]}
```

```story-node
{"node_id":"s04_002","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["枫月睁眼。"],"next":"s04_003"}
```

```story-node
{"node_id":"s04_003","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["岚音靠在门边，手臂缠着新绷带。"],"next":"s04_004"}
```

```story-node
{"node_id":"s04_004","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["还能动？"],"next":"s04_005"}
```

```story-node
{"node_id":"s04_005","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["能。"],"next":"s04_006"}
```

```story-node
{"node_id":"s04_006","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["那就起来。"],"next":"s04_007"}
```

```story-node
{"node_id":"s04_007","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["刚才输了。"],"next":"s04_008"}
```

```story-node
{"node_id":"s04_008","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["我看见了。"],"next":"s04_009"}
```

```story-node
{"node_id":"s04_009","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["你不觉得应该换个人？"],"next":"s04_010"}
```

```story-node
{"node_id":"s04_010","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["换谁？"],"next":"s04_011"}
```

```story-node
{"node_id":"s04_011","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["一个不会第一天就被兔子打进药棚的人。"],"next":"s04_012"}
```

```story-node
{"node_id":"s04_012","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["失败之后知道换办法，比第一次就会赢的人少见。"],"next":"s04_013"}
```

```story-node
{"node_id":"s04_013","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["苏芷从后面把药碗放下。"],"next":"s04_014"}
```

```story-node
{"node_id":"s04_014","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["先喝。"],"next":"s04_015"}
```

```story-node
{"node_id":"s04_015","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["苦吗？"],"next":"s04_016"}
```

```story-node
{"node_id":"s04_016","type":"dialogue","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["你刚才被兔王撞飞的时候没问这个。"],"next":"s04_017"}
```

```story-node
{"node_id":"s04_017","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["失败世界结果："],"next":"s04_018"}
```

```story-node
{"node_id":"s04_018","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["药田损失增加"],"next":"s04_019"}
```

```story-node
{"node_id":"s04_019","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["部分证据被清理"],"next":"s04_020"}
```

```story-node
{"node_id":"s04_020","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["兔王仍可在简化版追踪中处理"],"next":"s04_021"}
```

```story-node
{"node_id":"s04_021","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["不能重新回到“药田完全无损”版本"],"next":"s04_022"}
```

```story-node
{"node_id":"s04_022","type":"narrative","scene_id":"s04","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["关键装备仍通过捕网、遗留物或后续结算保底获得"],"next":"s05_001"}
```

## SCENE s05：岚音正式加入阶段同行

```story-node
{"node_id":"s05_001","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["事件结束后。"],"next":"s05_002"}
```

```story-node
{"node_id":"s05_002","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["岚音重新检查粉末痕迹。"],"next":"s05_003"}
```

```story-node
{"node_id":"s05_003","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["还没完？"],"next":"s05_004"}
```

```story-node
{"node_id":"s05_004","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["这种粉往北还有。"],"next":"s05_005"}
```

```story-node
{"node_id":"s05_005","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["你一直在追？"],"next":"s05_006"}
```

```story-node
{"node_id":"s05_006","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["我负责巡林。"],"next":"s05_007"}
```

```story-node
{"node_id":"s05_007","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["名字呢？"],"next":"s05_008"}
```

```story-node
{"node_id":"s05_008","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["岚音抬头。"],"next":"s05_009"}
```

```story-node
{"node_id":"s05_009","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["岚音。"],"next":"s05_010"}
```

```story-node
{"node_id":"s05_010","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["枫月。"],"next":"s05_011"}
```

```story-node
{"node_id":"s05_011","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["我知道。"],"next":"s05_012"}
```

```story-node
{"node_id":"s05_012","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["系统？"],"next":"s05_013"}
```

```story-node
{"node_id":"s05_013","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["顾村长喊了你好几次。"],"next":"s05_014"}
```

```story-node
{"node_id":"s05_014","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["远处响起狼嚎。"],"next":"s05_015"}
```

```story-node
{"node_id":"s05_015","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["岚音脸上的轻松消失。"],"next":"s05_016"}
```

```story-node
{"node_id":"s05_016","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["狼径。"],"next":"s05_017"}
```

```story-node
{"node_id":"s05_017","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["同一种粉？"],"next":"s05_018"}
```

```story-node
{"node_id":"s05_018","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["闻起来是。"],"next":"s05_019"}
```

```story-node
{"node_id":"s05_019","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["苏芷："],"next":"s05_020"}
```

```story-node
{"node_id":"s05_020","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["兔王活： “药田要修，但还能恢复。”"],"next":"s05_021"}
```

```story-node
{"node_id":"s05_021","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["兔王死： “材料你可以用，后果也记得看。”"],"next":"s05_022"}
```

```story-node
{"node_id":"s05_022","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["战败： “下次进战斗前先看血量。现实里疼的人也是你。”"],"next":"s05_023"}
```

```story-node
{"node_id":"s05_023","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["顾长川："],"next":"s05_024"}
```

```story-node
{"node_id":"s05_024","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["“你现在知道为什么我不喜欢只看任务结果了。”"],"next":"s05_025"}
```

```story-node
{"node_id":"s05_025","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["岚音："],"next":"s05_026"}
```

```story-node
{"node_id":"s05_026","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若高信任：“狼径我带路。你负责别乱跑。”"],"next":"s05_027"}
```

```story-node
{"node_id":"s05_027","type":"narrative","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若低信任：“跟紧。丢了我不会回头第二次。”"],"next":"s05_028"}
```

```story-node
{"node_id":"s05_028","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["第一次呢？"],"next":"s05_029"}
```

```story-node
{"node_id":"s05_029","type":"dialogue","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_LANYIN","expression":"neutral","portrait_action":"show","text":["看情况。"],"quest_actions":[{"action":"update_objective","quest_id":"NV_MAIN_003","objective_id":"resolve_rabbit_event","update":{"value":true}}],"next":"story_complete","relationship_actions":[{"relationship_id":"NV7_REL_FENGYUE_LANYIN","dimension":"trust","op":"inc","value":1}]}
```

## SCENE s02：限时调查

```story-node
{"node_id":"s02_investigation_choice","type":"choice","scene_id":"s02","location_id":"NV7_LOC_FIELDS","purpose":"investigation_priority","choices":[{"choice_id":"investigate_1","text":"检查捕兽夹碎片","intent":"检查捕兽夹碎片","protagonist_boundary":"allowed","visible_risk":"调查顺序","consequence_summary":"进入限时调查","hidden_consequence":"无","conditions":[],"effects":[],"goto":"s02_001"},{"choice_id":"investigate_2","text":"检查硬底靴印","intent":"检查硬底靴印","protagonist_boundary":"allowed","visible_risk":"调查顺序","consequence_summary":"进入限时调查","hidden_consequence":"无","conditions":[],"effects":[],"goto":"s02_001"},{"choice_id":"investigate_3","text":"检查蓝色驱兽粉","intent":"检查蓝色驱兽粉","protagonist_boundary":"allowed","visible_risk":"调查顺序","consequence_summary":"进入限时调查","hidden_consequence":"无","conditions":[],"effects":[],"goto":"s02_001"}]}
```

## SCENE s05：岚音正式加入阶段同行

```story-node
{"node_id":"story_complete","type":"complete","scene_id":"s05","location_id":"NV7_LOC_FIELDS","purpose":"r1_story_complete","terminal":true,"outcome":"nv_main_003_complete","next_story_id":"NV_MAIN_004"}
```

## SCENE s03：兔王出现

```story-node
{"node_id":"rabbit_route_1_combat","type":"combat","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"rabbit_event_route","combat_ref":"NV7_COMBAT_RABBIT_GUARDS","next_on_win":"s05_001","next_on_loss":"s04_001"}
```

```story-node
{"node_id":"rabbit_route_2_combat","type":"combat","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"rabbit_event_route","combat_ref":"NV7_COMBAT_POACHERS","next_on_win":"s05_001","next_on_loss":"s04_001"}
```

```story-node
{"node_id":"rabbit_route_3_combat","type":"combat","scene_id":"s03","location_id":"NV7_LOC_FIELDS","purpose":"rabbit_event_route","combat_ref":"NV7_COMBAT_DUDU_RABBIT","next_on_win":"s05_001","next_on_loss":"s04_001"}
```
