# TASK NV_MAIN_002《三份委托》

## META

```story-meta
{
  "quest": {
    "schema_version": "1.5.0",
    "quest_id": "NV_MAIN_002",
    "content_status": "complete_script",
    "title": "三份委托",
    "region_id": "NV7",
    "category": "main",
    "source_chapters": [
      "3",
      "4",
      "5"
    ],
    "source_refs": [
      "reviewed-package:R1.1/02_NV_MAIN_002_三份委托_COMPLETE_SCRIPT.md"
    ],
    "design": {
      "purpose": "第七新手村R1正式接入",
      "theme": "被困世界中的求证与协作",
      "emotion": "异常、试探、行动",
      "source": "审核通过的R1.1完整剧本包",
      "adaptation": "机械结构化，不改写核心台词",
      "conflict": "玩家在真实风险中判断行动",
      "mechanic": "对话、选择、任务与战斗引用",
      "start": "铁匠铺",
      "end": "第三界石",
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
        "scene_id": "a01",
        "title": "铁匠铺",
        "entry_nodes": [
          "a01_001"
        ],
        "exit_nodes": [
          "a01_choice_1"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_CHIEF",
          "NV7_NPC_HANSHI",
          "NV7_NPC_SUZHI"
        ],
        "objective": "铁匠铺",
        "optional_interactions": []
      },
      {
        "scene_id": "a02",
        "title": "训练木人",
        "entry_nodes": [
          "a02_001"
        ],
        "exit_nodes": [
          "a02_048"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_CHIEF",
          "NV7_NPC_HANSHI",
          "NV7_NPC_SUZHI"
        ],
        "objective": "训练木人",
        "optional_interactions": []
      },
      {
        "scene_id": "a03",
        "title": "矿车旁的灰背獾",
        "entry_nodes": [
          "a03_001"
        ],
        "exit_nodes": [
          "a03_choice_2"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_CHIEF",
          "NV7_NPC_HANSHI",
          "NV7_NPC_SUZHI"
        ],
        "objective": "矿车旁的灰背獾",
        "optional_interactions": []
      },
      {
        "scene_id": "b01",
        "title": "药棚",
        "entry_nodes": [
          "b01_001"
        ],
        "exit_nodes": [
          "b01_024"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_CHIEF",
          "NV7_NPC_HANSHI",
          "NV7_NPC_SUZHI"
        ],
        "objective": "药棚",
        "optional_interactions": []
      },
      {
        "scene_id": "b02",
        "title": "北坡采集",
        "entry_nodes": [
          "b02_001"
        ],
        "exit_nodes": [
          "b02_022"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_CHIEF",
          "NV7_NPC_HANSHI",
          "NV7_NPC_SUZHI"
        ],
        "objective": "北坡采集",
        "optional_interactions": []
      },
      {
        "scene_id": "b03",
        "title": "蓝色粉末",
        "entry_nodes": [
          "b03_001"
        ],
        "exit_nodes": [
          "b03_014"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_CHIEF",
          "NV7_NPC_HANSHI",
          "NV7_NPC_SUZHI"
        ],
        "objective": "蓝色粉末",
        "optional_interactions": []
      },
      {
        "scene_id": "c01",
        "title": "第一与第二界石",
        "entry_nodes": [
          "c01_001"
        ],
        "exit_nodes": [
          "c01_016"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_CHIEF",
          "NV7_NPC_HANSHI",
          "NV7_NPC_SUZHI"
        ],
        "objective": "第一与第二界石",
        "optional_interactions": []
      },
      {
        "scene_id": "c02",
        "title": "第三界石",
        "entry_nodes": [
          "c02_001"
        ],
        "exit_nodes": [
          "c02_065"
        ],
        "participant_ids": [
          "PROTAGONIST_FENGYUE",
          "NV7_NPC_CHIEF",
          "NV7_NPC_HANSHI",
          "NV7_NPC_SUZHI"
        ],
        "objective": "第三界石",
        "optional_interactions": []
      }
    ],
    "entry_node": "commission_start",
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
        "node_id": "c02_001"
      }
    ],
    "rewards": [
      {
        "type": "signal_only",
        "reward_id": "NV_MAIN_002_REWARD"
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
      "status_state_key": "quest.nv_main_002.status",
      "reward_granted_state_key": "quest.nv_main_002.reward_granted",
      "availability": {
        "all": [
          {
            "kind": "quest",
            "quest_id": "NV_MAIN_001",
            "op": "eq",
            "value": "completed"
          }
        ],
        "any": []
      },
      "objectives": [
        {
          "objective_id": "hanshi",
          "type": "boolean",
          "required": true,
          "progress_state_key": "quest.nv_main_002.objective.hanshi",
          "target": true
        },
        {
          "objective_id": "suzhi",
          "type": "boolean",
          "required": true,
          "progress_state_key": "quest.nv_main_002.objective.suzhi",
          "target": true
        },
        {
          "objective_id": "guchangchuan",
          "type": "boolean",
          "required": true,
          "progress_state_key": "quest.nv_main_002.objective.guchangchuan",
          "target": true
        }
      ],
      "completion_mode": "automatic",
      "failure": {
        "continuation_state_key": "quest.nv_main_002.continuation",
        "allowed_continuations": [
          "none",
          "hanshi_recovery",
          "suzhi_recovery",
          "boundary_recovery"
        ],
        "resume_from_failed": "active",
        "resume_from_suspended": "active",
        "reopen_allowed": true
      },
      "qualification": {
        "objective_ids": [
          "hanshi",
          "suzhi",
          "guchangchuan"
        ],
        "required_count": 2
      }
    },
    "allowed_loops": [
      {
        "loop_id": "parallel_commission_return",
        "node_ids": [
          "commission_hub"
        ],
        "max_recommended_repeats": 3,
        "has_exit": true
      }
    ],
    "test_cases": [
      {
        "test_id": "nv_main_002_start",
        "initial_state": {},
        "steps": [
          "commission_start"
        ],
        "expected": [
          "story_started"
        ]
      },
      {
        "test_id": "nv_main_002_route",
        "initial_state": {},
        "steps": [
          "commission_start"
        ],
        "expected": [
          "choice_or_dialogue"
        ]
      },
      {
        "test_id": "nv_main_002_complete",
        "initial_state": {},
        "steps": [
          "commission_start"
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
      "commission_start",
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
## SCENE a01：铁匠铺

```story-node
{"node_id":"a01_001","type":"narrative","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["韩石正夹着一块烧红的铁片。"],"next":"a01_002","quest_actions":[{"action":"activate","quest_id":"NV_MAIN_002"}]}
```

```story-node
{"node_id":"a01_002","type":"narrative","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["枫月刚跨过门槛，韩石头也不抬。"],"next":"a01_003"}
```

```story-node
{"node_id":"a01_003","type":"dialogue","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["墙角，拿一件。"],"next":"a01_004"}
```

```story-node
{"node_id":"a01_004","type":"narrative","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["枫月看过去。"],"next":"a01_005"}
```

```story-node
{"node_id":"a01_005","type":"narrative","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["一柄薄刃短剑、一面包铁木盾、一根带钩短杖靠在墙边。"],"next":"a01_choice_1"}
```

```story-node
{"node_id":"a01_choice_1_1_response","type":"narrative","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_choice_response","text":["枫月掂了掂。","韩石：“轻。快。挡不住重东西。”","枫月：“总结得很有销售热情。”","韩石：“免费东西，不需要销售。”"],"next":"a01_choice_1_1_response_reward"}
```

```story-node
{"node_id":"a01_choice_1_2_response","type":"narrative","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_choice_response","text":["枫月把盾扣在小臂上。","韩石：“能挡。”","枫月：“缺点？”","韩石：“你拿着它的时候，另一只手不会变多。”"],"next":"a01_choice_1_2_response_reward"}
```

```story-node
{"node_id":"a01_choice_1_3_response","type":"narrative","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_choice_response","text":["枫月试着挥动钩头。","韩石：“能拉东西，也能把自己拉进麻烦里。”","枫月：“你这里每件装备都有警告？”","韩石：“活着的人才有机会嫌我话多。”"],"next":"a01_choice_1_3_response_reward"}
```

```story-node
{"node_id":"a01_choice_1","type":"choice","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"reviewed_choice","choices":[{"choice_id":"a01_choice_1_a1","text":"薄刃短剑","intent":"薄刃短剑","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"a01_choice_1_1_response"},{"choice_id":"a01_choice_1_a2","text":"包铁木盾","intent":"包铁木盾","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"a01_choice_1_2_response"},{"choice_id":"a01_choice_1_a3","text":"猎钩短杖","intent":"猎钩短杖","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"a01_choice_1_3_response"}],"next":"a02_001"}
```

## SCENE a02：训练木人

```story-node
{"node_id":"a02_001","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["打它。"],"next":"a02_002"}
```

```story-node
{"node_id":"a02_002","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["就这样？"],"next":"a02_003"}
```

```story-node
{"node_id":"a02_003","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["它不会告你偷袭。"],"next":"a02_004"}
```

```story-node
{"node_id":"a02_004","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["进入训练木人战。"],"next":"a02_005"}
```

```story-node
{"node_id":"a02_005","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["第一轮，韩石不会解释全部规则。木人只做缓慢横扫，给玩家一个明显的观察窗口。"],"next":"a02_006"}
```

```story-node
{"node_id":"a02_006","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["若玩家主动选择【观察】："],"next":"a02_007"}
```

```story-node
{"node_id":"a02_007","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["【洞察：右臂起势过高，下一击为横扫；木轴回正前存在短暂空档。】"],"next":"a02_008"}
```

```story-node
{"node_id":"a02_008","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["看见了？"],"next":"a02_009"}
```

```story-node
{"node_id":"a02_009","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["看见它动作很大。"],"next":"a02_010"}
```

```story-node
{"node_id":"a02_010","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["够了。先看懂，再谈漂亮。"],"next":"a02_011"}
```

```story-node
{"node_id":"a02_011","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["若玩家第一轮直接攻击，木人被打中后会立即反摆。"],"next":"a02_012"}
```

```story-node
{"node_id":"a02_012","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["它不会疼。"],"next":"a02_013"}
```

```story-node
{"node_id":"a02_013","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["所以它也不会因为你打中了就停。"],"next":"a02_014"}
```

```story-node
{"node_id":"a02_014","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["系统在下一轮高亮【防御】。"],"next":"a02_015"}
```

```story-node
{"node_id":"a02_015","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["若玩家主动防御："],"next":"a02_016"}
```

```story-node
{"node_id":"a02_016","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["木人横扫落下，伤害明显降低。"],"next":"a02_017"}
```

```story-node
{"node_id":"a02_017","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["【防御状态持续至下一次行动，所受伤害降低40%】"],"next":"a02_018"}
```

```story-node
{"node_id":"a02_018","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["这个提示倒是很具体。"],"next":"a02_019"}
```

```story-node
{"node_id":"a02_019","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["数字负责告诉你少疼多少。"],"next":"a02_020"}
```

```story-node
{"node_id":"a02_020","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["你负责判断什么时候会疼。"],"next":"a02_021"}
```

```story-node
{"node_id":"a02_021","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["若玩家连续两轮未使用【观察】："],"next":"a02_022"}
```

```story-node
{"node_id":"a02_022","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["韩石会在木人侧面敲一下。"],"next":"a02_023"}
```

```story-node
{"node_id":"a02_023","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["停。"],"next":"a02_024"}
```

```story-node
{"node_id":"a02_024","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["他亲自转动木人右臂。"],"next":"a02_025"}
```

```story-node
{"node_id":"a02_025","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["看肩。看轴。看它先动哪里。"],"next":"a02_026"}
```

```story-node
{"node_id":"a02_026","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["系统随后强制开放一次低成本观察演示，不替玩家完成后续判断。"],"next":"a02_027"}
```

```story-node
{"node_id":"a02_027","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["若玩家连续两轮未使用【防御】："],"next":"a02_028"}
```

```story-node
{"node_id":"a02_028","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["韩石会让木人停在横扫前。"],"next":"a02_029"}
```

```story-node
{"node_id":"a02_029","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["你不是来证明自己能挨。"],"next":"a02_030"}
```

```story-node
{"node_id":"a02_030","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["系统随后触发一次防御演示。"],"next":"a02_031"}
```

```story-node
{"node_id":"a02_031","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["教学目标要求玩家在战斗结束前自然经历至少一次“观察→判断”和一次“防御→减伤”。若玩家没有主动选择，则由韩石通过中断训练补做演示，避免把教程写成硬性清单。"],"next":"a02_032"}
```

```story-node
{"node_id":"a02_032","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["技能说明在玩家首次打开技能栏时出现："],"next":"a02_033"}
```

```story-node
{"node_id":"a02_033","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["【技能消耗冷却与单场次数，不使用传统魔法值】"],"next":"a02_034"}
```

```story-node
{"node_id":"a02_034","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["战斗结束后。"],"next":"a02_035"}
```

```story-node
{"node_id":"a02_035","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["系统告诉你，挡一下能少挨四成。"],"next":"a02_036"}
```

```story-node
{"node_id":"a02_036","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["有问题？"],"next":"a02_037"}
```

```story-node
{"node_id":"a02_037","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["没问题。"],"next":"a02_038"}
```

```story-node
{"node_id":"a02_038","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["韩石把木人转了半圈，露出后面一道横裂。"],"next":"a02_039"}
```

```story-node
{"node_id":"a02_039","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["问题是它没告诉你，什么时候该挡。"],"next":"a02_040"}
```

```story-node
{"node_id":"a02_040","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["若玩家全程只攻击："],"next":"a02_041"}
```

```story-node
{"node_id":"a02_041","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["你打得很快。"],"next":"a02_042"}
```

```story-node
{"node_id":"a02_042","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["听起来不像夸奖。"],"next":"a02_043"}
```

```story-node
{"node_id":"a02_043","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["本来就不是。活的东西会还手。"],"next":"a02_044"}
```

```story-node
{"node_id":"a02_044","type":"narrative","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_narrative","text":["若玩家频繁防御："],"next":"a02_045"}
```

```story-node
{"node_id":"a02_045","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["会挡是好事。"],"next":"a02_046"}
```

```story-node
{"node_id":"a02_046","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["只挡不是。"],"next":"a02_047"}
```

```story-node
{"node_id":"a02_047","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["你这里连防御都有业绩指标？"],"next":"a02_048"}
```

```story-node
{"node_id":"a02_048","type":"dialogue","scene_id":"a02","location_id":"NV7_LOC_FORGE","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["有。活下来。"],"next":"a03_001"}
```

## SCENE a03：矿车旁的灰背獾

```story-node
{"node_id":"a03_001","type":"narrative","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["韩石要三块黑铁碎片。"],"next":"a03_002"}
```

```story-node
{"node_id":"a03_002","type":"narrative","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["两只灰背獾正在翻矿车。"],"next":"a03_choice_2"}
```

```story-node
{"node_id":"a03_choice_2_1_response","type":"narrative","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["胜利后枫月发现其中一只口鼻有蓝色粉末。","枫月：“这东西不像泥。”"],"next":"hanshi_badger_combat"}
```

```story-node
{"node_id":"a03_choice_2_2_response","type":"narrative","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["【洞察反馈：两只灰背獾均处于受惊状态；攻击欲低于正常值；嗅觉受刺激。】","枫月：“不是来找人的，是被什么东西赶过来的。”","可再选择驱赶或攻击。观察成功降低战斗难度。"],"next":"hanshi_badger_combat"}
```

```story-node
{"node_id":"a03_choice_2_3_response","type":"narrative","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["若 InventoryManager 中有可用食物，消耗 1 份。","两只灰背獾迟疑后跟着气味离开。","枫月：“至少今天不用和獾讨论生死。”"],"next":"hanshi_badger_combat"}
```

```story-node
{"node_id":"a03_choice_2_4_response","type":"narrative","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["枫月捡起一块铁片，先判断风向和两只灰背獾的退路。","若此前已观察：","他把铁片砸向矿车另一侧。","灰背獾同时受惊，却没有扑来，而是顺着唯一没有刺激气味的缺口钻进林中。","结果：完全成功，不进入战斗。","若未观察，但玩家先检查周围：","第一只灰背獾被惊走，第二只误以为自己被包围，原地炸毛。","结果：部分成功，只与单只灰背獾战斗。","若既未观察也未检查退路：","铁片落在它们身后，把两只灰背獾都逼向枫月。","结果：失败，进入双体战。","韩石事后会评价：“声响不是方向。你把路堵错了。”","战斗或驱赶结束后，枫月没有立刻拿矿石。","如果其中一只灰背獾受伤逃走，他会看到它在远处停下，不断用前爪蹭鼻子。","如果两只都被引开，矿车底下则能找到被抓挠出的蓝色粉末痕迹。","枫月蹲下看了一会儿。","枫月：“它们不是突然胆子变大。”","若岚音尚未登场，不出现他人回应，只保留枫月自己的判断。","若玩家此前从苏芷处已得知驱兽粉：","枫月：“同一种味道。”","这个重复发现不会立刻写成长期世界真相，只强化玩家对“异常不是单点事件”的认知。","取得黑铁碎片后返回。","韩石把其中一块放上铁砧，敲开表层。","里面有一线极细的银色纹路。","韩石：“这不是我们这边的矿。”","枫月：“石头也分户籍？”","韩石：“矿脉会。”","韩石：“这种银纹，我以前只在旧界石碎片里见过。”","枫月：“最近才出现？”","韩石：“最近明显多了。”","韩石把碎片收入铁盒。","韩石：“别把不知道的东西先叫宝物。”","枫月：“那叫什么？”","韩石：“麻烦。”","奖励由 QuestManager 幂等结算。","若玩家发现蓝粉，只记录为本任务局部线索；真正长期证据要在 NV_MAIN_003 确认后才进入 GameState。"],"next":"hanshi_badger_combat"}
```

```story-node
{"node_id":"a03_choice_2","type":"choice","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice","choices":[{"choice_id":"a03_choice_2_b1","text":"直接攻击","intent":"直接攻击","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"a03_choice_2_1_response"},{"choice_id":"a03_choice_2_b2","text":"先观察","intent":"先观察","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"a03_choice_2_2_response"},{"choice_id":"a03_choice_2_b3","text":"拿食物引开","intent":"拿食物引开","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"a03_choice_2_3_response"},{"choice_id":"a03_choice_2_b4","text":"制造声响驱赶","intent":"制造声响驱赶","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"a03_choice_2_4_response"}],"next":"b01_001"}
```

## SCENE b01：药棚

```story-node
{"node_id":"b01_001","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["门口木牌写着："],"next":"b01_002"}
```

```story-node
{"node_id":"b01_002","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["“先说伤势，再问价格。”"],"next":"b01_003"}
```

```story-node
{"node_id":"b01_003","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["若玩家在 NV_MAIN_001 测试过痛觉："],"next":"b01_004"}
```

```story-node
{"node_id":"b01_004","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["苏芷看了枫月手臂一眼。"],"next":"b01_005"}
```

```story-node
{"node_id":"b01_005","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["结论有了吗？"],"next":"b01_006"}
```

```story-node
{"node_id":"b01_006","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["什么？"],"next":"b01_007"}
```

```story-node
{"node_id":"b01_007","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["你会不会疼。"],"next":"b01_008"}
```

```story-node
{"node_id":"b01_008","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["枫月低头。"],"next":"b01_009"}
```

```story-node
{"node_id":"b01_009","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["有了。"],"next":"b01_010"}
```

```story-node
{"node_id":"b01_010","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["那就别再试第二次。"],"next":"b01_011"}
```

```story-node
{"node_id":"b01_011","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["若没测试："],"next":"b01_012"}
```

```story-node
{"node_id":"b01_012","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["祭坛上新来的？"],"next":"b01_013"}
```

```story-node
{"node_id":"b01_013","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["这么明显？"],"next":"b01_014"}
```

```story-node
{"node_id":"b01_014","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["老冒险者进门先问药价。"],"next":"b01_015"}
```

```story-node
{"node_id":"b01_015","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["新人呢？"],"next":"b01_016"}
```

```story-node
{"node_id":"b01_016","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["先问自己会不会死。"],"next":"b01_017"}
```

```story-node
{"node_id":"b01_017","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["苏芷递出药篮。"],"next":"b01_018"}
```

```story-node
{"node_id":"b01_018","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["需求："],"next":"b01_019"}
```

```story-node
{"node_id":"b01_019","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["月露草 3"],"next":"b01_020"}
```

```story-node
{"node_id":"b01_020","type":"narrative","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["止血藤 2"],"next":"b01_021"}
```

```story-node
{"node_id":"b01_021","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["月露草摘叶，不拔根。"],"next":"b01_022"}
```

```story-node
{"node_id":"b01_022","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["止血藤切三寸，别把整条藤拖回来。"],"next":"b01_023"}
```

```story-node
{"node_id":"b01_023","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["为什么？"],"next":"b01_024"}
```

```story-node
{"node_id":"b01_024","type":"dialogue","scene_id":"b01","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["因为明天还要用。"],"next":"b02_001"}
```

## SCENE b02：北坡采集

```story-node
{"node_id":"b02_001","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["玩家可执行多种方法。"],"next":"b02_choice_3"}
```

```story-node
{"node_id":"b02_choice_3_1_response","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["获得高质量药材。","枫月：“终于有一个不会还手的任务。”","草丛里一只虫飞出来。","枫月：“……暂时。”"],"next":"b02_003"}
```

```story-node
{"node_id":"b02_choice_3_2_response","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["可更快完成，但部分药材质量普通。","返回时苏芷检查：","苏芷：“够数。”","枫月：“听起来没有下半句。”","苏芷：“有。能用，但浪费了。”","不扣关系，只降低额外奖励。"],"next":"b02_003"}
```

```story-node
{"node_id":"b02_choice_3_3_response","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["【洞察反馈：部分叶片背面存在非自然蓝色粉末。】","枫月用纸包取样。"],"next":"b02_003"}
```

```story-node
{"node_id":"b02_choice_3_4_response","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["玩家可超量采摘。","系统提示不会阻止。","返回时苏芷把多余药材分开。","苏芷：“这些根断了。”","枫月：“系统显示可采集。”","苏芷：“系统显示的是你拿得到。”","苏芷：“没说拿了以后还能不能长。”"],"next":"b02_003"}
```

```story-node
{"node_id":"b02_choice_3","type":"choice","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice","choices":[{"choice_id":"b02_choice_3_c1","text":"仔细按要求采","intent":"仔细按要求采","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"b02_choice_3_1_response"},{"choice_id":"b02_choice_3_c2","text":"快速采满","intent":"快速采满","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"b02_choice_3_2_response"},{"choice_id":"b02_choice_3_c3","text":"使用洞察","intent":"使用洞察","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"b02_choice_3_3_response"},{"choice_id":"b02_choice_3_c4","text":"额外多采","intent":"额外多采","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"b02_choice_3_4_response"}],"next":"b02_003"}
```

```story-node
{"node_id":"b02_003","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["玩家采到第一株月露草后，系统会弹出【可采集】提示。"],"next":"b02_004"}
```

```story-node
{"node_id":"b02_004","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若玩家只取叶片："],"next":"b02_005"}
```

```story-node
{"node_id":"b02_005","type":"dialogue","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["系统没说要留根。"],"next":"b02_006"}
```

```story-node
{"node_id":"b02_006","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["他停了一下。"],"next":"b02_007"}
```

```story-node
{"node_id":"b02_007","type":"dialogue","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["但苏芷说了。"],"next":"b02_008"}
```

```story-node
{"node_id":"b02_008","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若玩家拔出整株："],"next":"b02_009"}
```

```story-node
{"node_id":"b02_009","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["根部带出一大块湿土。"],"next":"b02_010"}
```

```story-node
{"node_id":"b02_010","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["枫月看着手里的整株草。"],"next":"b02_011"}
```

```story-node
{"node_id":"b02_011","type":"dialogue","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["拿得到，和该不该拿，确实不是一回事。"],"next":"b02_012"}
```

```story-node
{"node_id":"b02_012","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["第二处止血藤缠在低树上，旁边有一段被野兽踩断的旧藤。"],"next":"b02_013"}
```

```story-node
{"node_id":"b02_013","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若玩家先观察："],"next":"b02_014"}
```

```story-node
{"node_id":"b02_014","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["可以从断口判断三寸长度，获得高质量采集。"],"next":"b02_015"}
```

```story-node
{"node_id":"b02_015","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若直接切："],"next":"b02_016"}
```

```story-node
{"node_id":"b02_016","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["有概率切长或切短。切长不影响主线，只降低附加奖励；切短则需要额外寻找一处采集点。"],"next":"b02_017"}
```

```story-node
{"node_id":"b02_017","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若玩家携带蓝粉样本准备回村，返程时会遇到一只不停打喷嚏的小型林鼠。"],"next":"b02_018"}
```

```story-node
{"node_id":"b02_018","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["玩家可选择："],"next":"b02_019"}
```

```story-node
{"node_id":"b02_019","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["不管，保留全部时间；"],"next":"b02_020"}
```

```story-node
{"node_id":"b02_020","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["用水冲掉它鼻端粉末；"],"next":"b02_021"}
```

```story-node
{"node_id":"b02_021","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["观察它逃跑方向。"],"next":"b02_022"}
```

```story-node
{"node_id":"b02_022","type":"narrative","scene_id":"b02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["选择帮助不会提供数值奖励，只让苏芷在回访时得知“粉末对小型动物同样有效”，增加一条调查对白。"],"next":"b03_001"}
```

## SCENE b03：蓝色粉末

```story-node
{"node_id":"b03_001","type":"narrative","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["若带回样本："],"next":"b03_002"}
```

```story-node
{"node_id":"b03_002","type":"narrative","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["苏芷把银针插入粉末。"],"next":"b03_003"}
```

```story-node
{"node_id":"b03_003","type":"narrative","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["针尖迅速发黑。"],"next":"b03_004"}
```

```story-node
{"node_id":"b03_004","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["驱兽粉。"],"next":"b03_005"}
```

```story-node
{"node_id":"b03_005","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["有人在赶动物？"],"next":"b03_006"}
```

```story-node
{"node_id":"b03_006","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["里面还混了让它们更容易惊恐的东西。"],"next":"b03_007"}
```

```story-node
{"node_id":"b03_007","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["谁做的？"],"next":"b03_008"}
```

```story-node
{"node_id":"b03_008","type":"narrative","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["苏芷看他一眼。"],"next":"b03_009"}
```

```story-node
{"node_id":"b03_009","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["你看到一撮粉，就已经准备给凶手定罪了？"],"next":"b03_010"}
```

```story-node
{"node_id":"b03_010","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["我只是问。"],"next":"b03_011"}
```

```story-node
{"node_id":"b03_011","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["那就先把问题留成问题。"],"next":"b03_012"}
```

```story-node
{"node_id":"b03_012","type":"narrative","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_narrative","text":["她把样本封进小瓶。"],"next":"b03_013"}
```

```story-node
{"node_id":"b03_013","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["记住异常。"],"next":"b03_014"}
```

```story-node
{"node_id":"b03_014","type":"dialogue","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["别急着记住答案。"],"next":"b03_evidence_reward","quest_actions":[{"action":"update_objective","quest_id":"NV_MAIN_002","objective_id":"suzhi","update":{"value":true}}],"relationship_actions":[{"relationship_id":"NV7_REL_FENGYUE_SUZHI","dimension":"trust","op":"inc","value":1}]}
```

## SCENE c01：第一与第二界石

```story-node
{"node_id":"c01_001","type":"narrative","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["顾长川交给枫月一支测纹粉笔。"],"next":"c01_002"}
```

```story-node
{"node_id":"c01_002","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["三块界石，沿北边走。"],"next":"c01_003"}
```

```story-node
{"node_id":"c01_003","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["为什么让我去？"],"next":"c01_004"}
```

```story-node
{"node_id":"c01_004","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["你能看系统回波。"],"next":"c01_005"}
```

```story-node
{"node_id":"c01_005","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["其他冒险者不能？"],"next":"c01_006"}
```

```story-node
{"node_id":"c01_006","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["能。"],"next":"c01_007"}
```

```story-node
{"node_id":"c01_007","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["只是你刚才在祭坛上，回波出现得比常见情况快一点。"],"next":"c01_008"}
```

```story-node
{"node_id":"c01_008","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["这算特殊？"],"next":"c01_009"}
```

```story-node
{"node_id":"c01_009","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["算麻烦。"],"next":"c01_010"}
```

```story-node
{"node_id":"c01_010","type":"dialogue","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["不是唯一，也不是神迹。别急着给自己加戏。"],"next":"c01_011"}
```

```story-node
{"node_id":"c01_011","type":"narrative","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["此处明确修复 v1.3 冲突。"],"next":"c01_012"}
```

```story-node
{"node_id":"c01_012","type":"narrative","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["第一块界石：光芒偏弱。"],"next":"c01_013"}
```

```story-node
{"node_id":"c01_013","type":"narrative","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["第二块界石：表层裂纹。"],"next":"c01_014"}
```

```story-node
{"node_id":"c01_014","type":"narrative","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["玩家可选择是否认真记录。"],"next":"c01_015"}
```

```story-node
{"node_id":"c01_015","type":"narrative","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若敷衍："],"next":"c01_016"}
```

```story-node
{"node_id":"c01_016","type":"narrative","scene_id":"c01","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["顾长川回访时会指出漏记，但任务仍可完成，奖励减少。"],"next":"c02_001"}
```

## SCENE c02：第三界石

```story-node
{"node_id":"c02_001","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["枫月第一次触碰时只看到【外部坐标校验失败】。"],"next":"c02_002"}
```

```story-node
{"node_id":"c02_002","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若立刻松手，顾长川赶到后会称赞一句："],"next":"c02_003"}
```

```story-node
{"node_id":"c02_003","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["至少你知道看不懂的时候先停。"],"next":"c02_004"}
```

```story-node
{"node_id":"c02_004","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若继续触碰："],"next":"c02_005"}
```

```story-node
{"node_id":"c02_005","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["第二层回波出现："],"next":"c02_006"}
```

```story-node
{"node_id":"c02_006","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["【回波来源：多重】"],"next":"c02_007"}
```

```story-node
{"node_id":"c02_007","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["视野边缘短暂叠出数个不同方向的白色线框，像几张地图同时压在一起。"],"next":"c02_008"}
```

```story-node
{"node_id":"c02_008","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["枫月下意识后退半步。"],"next":"c02_009"}
```

```story-node
{"node_id":"c02_009","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["顾长川这时用厚布盖住界石。"],"next":"c02_010"}
```

```story-node
{"node_id":"c02_010","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若玩家第三次强行触碰："],"next":"c02_011"}
```

```story-node
{"node_id":"c02_011","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["触发轻度回波冲击，直接进入失败续接版，不提供更多真相。"],"next":"c02_012"}
```

```story-node
{"node_id":"c02_012","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["这样明确“继续试并不会免费得到更多情报”。"],"next":"c02_013"}
```

```story-node
{"node_id":"c02_013","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["第三块界石有银色细裂。"],"next":"c02_014"}
```

```story-node
{"node_id":"c02_014","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["枫月手指触碰表面。"],"next":"c02_015"}
```

```story-node
{"node_id":"c02_015","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["【外部坐标校验失败】"],"next":"c02_016"}
```

```story-node
{"node_id":"c02_016","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["【回波来源：多重】"],"next":"c02_017"}
```

```story-node
{"node_id":"c02_017","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["界面闪烁。"],"next":"c02_018"}
```

```story-node
{"node_id":"c02_018","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["多重？"],"next":"c02_019"}
```

```story-node
{"node_id":"c02_019","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["顾长川从后方快步走来，用厚布盖住石面。"],"next":"c02_020"}
```

```story-node
{"node_id":"c02_020","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["手拿开。"],"next":"c02_choice_4"}
```

```story-node
{"node_id":"c02_choice_4_1_response","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["枫月：“你知道这是什么。”","顾长川：“知道一点。”","枫月：“一点是多少？”","顾长川：“少到不足以让你拿命去验证。”","枫月：“那你至少该告诉我，为什么它和祭坛的提示那么像。”","顾长川：“因为它们本来就是一套旧结构的一部分。”","即时结果：提前知道“祭坛与界石同源”。"],"next":"c02_022"}
```

```story-node
{"node_id":"c02_choice_4_2_response","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["枫月收回手。","顾长川：“不问？”","枫月：“问了你也不会全说。”","顾长川：“聪明。”","枫月：“不是。只是你写在脸上了。”"],"next":"c02_022"}
```

```story-node
{"node_id":"c02_choice_4_3_response","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice_response","text":["枫月：“我不信你。”","顾长川：“可以。”","枫月：“这么干脆？”","顾长川：“信任不是任务奖励。”","顾长川：“你先看我做过什么，再决定。”"],"next":"c02_022"}
```

```story-node
{"node_id":"c02_choice_4","type":"choice","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_choice","choices":[{"choice_id":"c02_choice_4_d1","text":"逼问","intent":"逼问","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"c02_choice_4_1_response"},{"choice_id":"c02_choice_4_d2","text":"暂时接受","intent":"暂时接受","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"c02_choice_4_2_response"},{"choice_id":"c02_choice_4_d3","text":"明确不信任","intent":"明确不信任","protagonist_boundary":"allowed","visible_risk":"可见后果见选项文本","consequence_summary":"进入审核稿声明的对应回应","hidden_consequence":"无额外隐藏改写","conditions":[],"effects":[],"goto":"c02_choice_4_3_response"}],"next":"c02_022"}
```

```story-node
{"node_id":"c02_022","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["最近有些冒险者会触发不同程度的异常回波。"],"next":"c02_023"}
```

```story-node
{"node_id":"c02_023","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["你更容易看到它们，仅此而已。"],"next":"c02_024"}
```

```story-node
{"node_id":"c02_024","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["所以不是只有我。"],"next":"c02_025"}
```

```story-node
{"node_id":"c02_025","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["当然不是。"],"next":"c02_026"}
```

```story-node
{"node_id":"c02_026","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["你们最危险的毛病之一，就是刚看见一扇怪门，就觉得门后一定写着自己的名字。"],"next":"c02_027"}
```

```story-node
{"node_id":"c02_027","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["当数量首次达到 2："],"next":"c02_028"}
```

```story-node
{"node_id":"c02_028","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["[BG_SHAKE: 轻]"],"next":"c02_029"}
```

```story-node
{"node_id":"c02_029","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["一名村民从北边跑进广场。"],"next":"c02_030"}
```

```story-node
{"node_id":"c02_030","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["村民：“药田！”"],"next":"c02_031"}
```

```story-node
{"node_id":"c02_031","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["村民：“兔群冲进北药田了！”"],"next":"c02_032"}
```

```story-node
{"node_id":"c02_032","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["苏芷从药棚出来，脸色瞬间变了。"],"next":"c02_033"}
```

```story-node
{"node_id":"c02_033","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["多少？"],"next":"c02_034"}
```

```story-node
{"node_id":"c02_034","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["村民：“一大片！篱笆全乱了！”"],"next":"c02_035"}
```

```story-node
{"node_id":"c02_035","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["韩石抬头望向北方。"],"next":"c02_036"}
```

```story-node
{"node_id":"c02_036","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["兔子不会平白无故往人堆里撞。"],"next":"c02_037"}
```

```story-node
{"node_id":"c02_037","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["顾长川看向枫月。"],"next":"c02_038"}
```

```story-node
{"node_id":"c02_038","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["你的第三件事可以晚点做。"],"next":"c02_039"}
```

```story-node
{"node_id":"c02_039","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["我猜现在有第四件。"],"next":"c02_040"}
```

```story-node
{"node_id":"c02_040","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["系统："],"next":"c02_041"}
```

```story-node
{"node_id":"c02_041","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["【主线更新：兔王不该出现】"],"next":"c02_042"}
```

```story-node
{"node_id":"c02_042","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若三项全部完成后才触发："],"next":"c02_043"}
```

```story-node
{"node_id":"c02_043","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["顾长川追加：“三件都做完了。很好。”"],"next":"c02_044"}
```

```story-node
{"node_id":"c02_044","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["苏芷递完整药包。"],"next":"c02_045"}
```

```story-node
{"node_id":"c02_045","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["韩石完成一次免费加固。"],"next":"c02_046"}
```

```story-node
{"node_id":"c02_046","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["proposed_item_id:consumable_novice_medkit_complete x1"],"next":"c02_047"}
```

```story-node
{"node_id":"c02_047","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["对已选初始装备执行一次任务型强化"],"next":"c02_048"}
```

```story-node
{"node_id":"c02_048","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["proposed_item_id:quest_old_boundary_rubbing x1"],"next":"c02_049"}
```

```story-node
{"node_id":"c02_049","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若只完成两项："],"next":"c02_050"}
```

```story-node
{"node_id":"c02_050","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["未完成委托保持可回访，不阻止兔王主线。"],"next":"c02_051"}
```

```story-node
{"node_id":"c02_051","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["枫月在药棚醒来。"],"next":"c02_052"}
```

```story-node
{"node_id":"c02_052","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["灰背獾不会追到村里来。"],"next":"c02_053"}
```

```story-node
{"node_id":"c02_053","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["这算安慰？"],"next":"c02_054"}
```

```story-node
{"node_id":"c02_054","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["算地图知识。"],"next":"c02_055"}
```

```story-node
{"node_id":"c02_055","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["任务重新开放，灰背獾位置改变；已获得的观察信息保留。"],"next":"c02_056"}
```

```story-node
{"node_id":"c02_056","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["苏芷处理伤口后减少任务奖励，不重置采集点，只补足最低任务所需刷新。"],"next":"c02_057"}
```

```story-node
{"node_id":"c02_057","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["若玩家连续强行触摸第三界石："],"next":"c02_058"}
```

```story-node
{"node_id":"c02_058","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["枫月短暂昏厥，在顾长川身边醒来。"],"next":"c02_059"}
```

```story-node
{"node_id":"c02_059","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["第二次还是同一个结果。"],"next":"c02_060"}
```

```story-node
{"node_id":"c02_060","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"PROTAGONIST_FENGYUE","expression":"neutral","portrait_action":"hide","text":["你可以早点拦。"],"next":"c02_061"}
```

```story-node
{"node_id":"c02_061","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["我拦了。你不听。"],"next":"c02_062"}
```

```story-node
{"node_id":"c02_062","type":"narrative","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_narrative","text":["任务继续，异常回波信息保留。"],"next":"c02_063"}
```

```story-node
{"node_id":"c02_063","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_HANSHI","expression":"neutral","portrait_action":"show","text":["别因为赢了两只獾就觉得世界好说话。"],"next":"c02_064"}
```

```story-node
{"node_id":"c02_064","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_SUZHI","expression":"calm","portrait_action":"show","text":["药是给还想活的人准备的，记得用。"],"next":"c02_065"}
```

```story-node
{"node_id":"c02_065","type":"dialogue","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"reviewed_dialogue","speaker_id":"NV7_NPC_CHIEF","expression":"calm","portrait_action":"show","text":["做完两件能出门，三件都做完能少吃一点亏。规则就是这样。"],"quest_actions":[{"action":"update_objective","quest_id":"NV_MAIN_002","objective_id":"guchangchuan","update":{"value":true}}],"next":"c02_evidence_reward","relationship_actions":[{"relationship_id":"NV7_REL_FENGYUE_GUCHANGCHUAN","dimension":"respect","op":"inc","value":1}]}
```

```story-node
{"node_id":"story_complete","type":"complete","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"r1_story_complete","terminal":true,"outcome":"nv_main_002_complete","next_story_id":"NV_MAIN_003"}
```

## SCENE a01：铁匠铺

```story-node
{"node_id":"commission_hub","type":"choice","scene_id":"a01","location_id":"NV7_LOC_SQUARE","purpose":"parallel_commission_hub","choices":[{"choice_id":"commission_hanshi","text":"韩石的试刃","intent":"执行并行委托","protagonist_boundary":"allowed","visible_risk":"委托中可能受伤","consequence_summary":"完成该委托目标","hidden_consequence":"无","conditions":[{"key":"quest.nv_main_002.objective.hanshi","op":"eq","value":false}],"effects":[],"goto":"a01_001","hidden_when_locked":true},{"choice_id":"commission_suzhi","text":"苏芷的药篮","intent":"执行并行委托","protagonist_boundary":"allowed","visible_risk":"委托中可能受伤","consequence_summary":"完成该委托目标","hidden_consequence":"无","conditions":[{"key":"quest.nv_main_002.objective.suzhi","op":"eq","value":false}],"effects":[],"goto":"b01_001","hidden_when_locked":true},{"choice_id":"commission_guchangchuan","text":"顾长川的界石","intent":"执行并行委托","protagonist_boundary":"allowed","visible_risk":"委托中可能受伤","consequence_summary":"完成该委托目标","hidden_consequence":"无","conditions":[{"key":"quest.nv_main_002.objective.guchangchuan","op":"eq","value":false}],"effects":[],"goto":"c01_001","hidden_when_locked":true},{"choice_id":"continue_main_story","text":"前往下一阶段","intent":"推进主线","protagonist_boundary":"allowed","visible_risk":"未完成的第三份委托仍可回访","consequence_summary":"任意两项完成后推进","hidden_consequence":"全清反馈取决于第三项目标","conditions":[{"key":"quest.nv_main_002.status","op":"in","value":["qualified","completed"]}],"effects":[],"goto":"story_complete","hidden_when_locked":true}]}
```

```story-node
{"node_id":"commission_start","type":"narrative","scene_id":"a01","location_id":"NV7_LOC_SQUARE","purpose":"parallel_commission_start","text":["三个委托没有固定顺序。完成任意两项后可以继续推进，第三项仍可回访。"],"quest_actions":[{"action":"activate","quest_id":"NV_MAIN_002"}],"next":"commission_hub"}
```

```story-node
{"node_id":"a01_choice_1_1_response_reward","type":"reward","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"selected_starter_equipment","reward_item_ids":["NV7_ITEM_NOVICE_SWORD"],"reward_items":[{"item_id":"NV7_ITEM_NOVICE_SWORD","quantity":1}],"next":"a02_001"}
```

```story-node
{"node_id":"a01_choice_1_2_response_reward","type":"reward","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"selected_starter_equipment","reward_item_ids":["NV7_ITEM_NOVICE_SHIELD"],"reward_items":[{"item_id":"NV7_ITEM_NOVICE_SHIELD","quantity":1}],"next":"a02_001"}
```

```story-node
{"node_id":"a01_choice_1_3_response_reward","type":"reward","scene_id":"a01","location_id":"NV7_LOC_FORGE","purpose":"selected_starter_equipment","reward_item_ids":["NV7_ITEM_NOVICE_HOOK_STAFF"],"reward_items":[{"item_id":"NV7_ITEM_NOVICE_HOOK_STAFF","quantity":1}],"next":"a02_001"}
```

## SCENE a03：矿车旁的灰背獾

```story-node
{"node_id":"hanshi_badger_combat","type":"combat","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"basic_combat_commission","combat_ref":"NV7_COMBAT_GREY_BADGERS","next_on_win":"hanshi_route_success","next_on_loss":"hanshi_route_recovery"}
```

```story-node
{"node_id":"hanshi_route_success","type":"narrative","scene_id":"a03","location_id":"NV7_LOC_FIELDS","purpose":"commission_result","text":["战斗胜利后，矿车附近恢复通行。"],"quest_actions":[{"action":"update_objective","quest_id":"NV_MAIN_002","objective_id":"hanshi","update":{"value":true}}],"relationship_actions":[{"relationship_id":"NV7_REL_FENGYUE_HANSHI","dimension":"respect","op":"inc","value":1}],"next":"commission_hub"}
```

```story-node
{"node_id":"hanshi_route_recovery","type":"narrative","scene_id":"a03","location_id":"NV7_LOC_APOTHECARY","purpose":"failure_continuation","text":["枫月在药棚醒来。","灰背獾不会追到村里来。任务重新开放，已获得的观察信息保留。"],"quest_actions":[{"action":"fail","quest_id":"NV_MAIN_002","continuation_id":"hanshi_recovery"},{"action":"resume","quest_id":"NV_MAIN_002"}],"next":"commission_hub"}
```

## SCENE b03：蓝色粉末

```story-node
{"node_id":"b03_evidence_reward","type":"reward","scene_id":"b03","location_id":"NV7_LOC_APOTHECARY","purpose":"commission_evidence_reward","reward_item_ids":["NV7_ITEM_BLUE_POWDER_SAMPLE"],"reward_items":[{"item_id":"NV7_ITEM_BLUE_POWDER_SAMPLE","quantity":1}],"next":"commission_hub"}
```

## SCENE c02：第三界石

```story-node
{"node_id":"c02_evidence_reward","type":"reward","scene_id":"c02","location_id":"NV7_LOC_FIELDS","purpose":"commission_evidence_reward","reward_item_ids":["NV7_ITEM_BOUNDARY_RUBBING"],"reward_items":[{"item_id":"NV7_ITEM_BOUNDARY_RUBBING","quantity":1}],"next":"commission_hub"}
```
