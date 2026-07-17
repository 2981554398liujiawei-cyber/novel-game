# 没有退出键

> 本文件由运行JSON自动生成，只供审阅；请勿手工作为权威源修改。

## 元数据

```json
{
  "schema_version": "1.5.0",
  "quest_id": "NV_MAIN_001",
  "content_status": "data_ready",
  "title": "没有退出键",
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
    "start": "黑暗之后",
    "end": "可选回访，第二次尝试",
    "feedback": "保留任务后回访"
  },
  "prerequisites": [],
  "mutual_exclusions": [],
  "trigger": {
    "method": "story_chain",
    "location_id": "NV7_LOC_ALTAR",
    "conditions": [],
    "opening_presentation": {}
  },
  "scenes": [
    {
      "scene_id": "s01",
      "title": "黑暗之后",
      "entry_nodes": [
        "s01_001"
      ],
      "exit_nodes": [
        "s01_023"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_CHIEF",
        "NV7_NPC_SUZHI"
      ],
      "objective": "黑暗之后",
      "optional_interactions": []
    },
    {
      "scene_id": "s02",
      "title": "身体不是手柄",
      "entry_nodes": [
        "s02_001"
      ],
      "exit_nodes": [
        "s02_020"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_CHIEF",
        "NV7_NPC_SUZHI"
      ],
      "objective": "身体不是手柄",
      "optional_interactions": []
    },
    {
      "scene_id": "s03",
      "title": "现实这个词",
      "entry_nodes": [
        "s03_001"
      ],
      "exit_nodes": [
        "s03_007"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_CHIEF",
        "NV7_NPC_SUZHI"
      ],
      "objective": "现实这个词",
      "optional_interactions": []
    },
    {
      "scene_id": "s04",
      "title": "一壶水的重量",
      "entry_nodes": [
        "s04_001"
      ],
      "exit_nodes": [
        "s04_026"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_CHIEF",
        "NV7_NPC_SUZHI"
      ],
      "objective": "一壶水的重量",
      "optional_interactions": []
    },
    {
      "scene_id": "s05",
      "title": "村心广场",
      "entry_nodes": [
        "s05_001"
      ],
      "exit_nodes": [
        "s05_024"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_CHIEF",
        "NV7_NPC_SUZHI"
      ],
      "objective": "村心广场",
      "optional_interactions": []
    },
    {
      "scene_id": "s06",
      "title": "可选回访，第二次尝试",
      "entry_nodes": [
        "s06_001"
      ],
      "exit_nodes": [
        "s06_020"
      ],
      "participant_ids": [
        "PROTAGONIST_FENGYUE",
        "NV7_NPC_CHIEF",
        "NV7_NPC_SUZHI"
      ],
      "objective": "可选回访，第二次尝试",
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
      "node_id": "s06_001"
    }
  ],
  "rewards": [
    {
      "type": "signal_only",
      "reward_id": "NV_MAIN_001_REWARD"
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
          "RETURN_CHANNEL",
          "WORLD_REALITY",
          "PLAYERS_TRAPPED"
        ]
      }
    }
  },
  "runtime": {
    "status_state_key": "quest.nv_main_001.status",
    "reward_granted_state_key": "quest.nv_main_001.reward_granted",
    "availability": {
      "all": [],
      "any": []
    },
    "objectives": [
      {
        "objective_id": "arrival",
        "type": "boolean",
        "required": true,
        "progress_state_key": "quest.nv_main_001.objective.arrival",
        "target": true
      }
    ],
    "completion_mode": "automatic",
    "failure": {
      "continuation_state_key": "quest.nv_main_001.continuation",
      "allowed_continuations": [
        "none",
        "altar_boundary_retry"
      ],
      "resume_from_failed": "active",
      "resume_from_suspended": "active",
      "reopen_allowed": true
    }
  },
  "allowed_loops": [],
  "test_cases": [
    {
      "test_id": "nv_main_001_start",
      "initial_state": {},
      "steps": [
        "s01_001"
      ],
      "expected": [
        "story_started"
      ]
    },
    {
      "test_id": "nv_main_001_route",
      "initial_state": {},
      "steps": [
        "s01_001"
      ],
      "expected": [
        "choice_or_dialogue"
      ]
    },
    {
      "test_id": "nv_main_001_complete",
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "黑暗先有了声音。"
  ],
  "next": "s01_002",
  "quest_actions": [
    {
      "action": "activate",
      "quest_id": "NV_MAIN_001"
    }
  ],
  "effects": [
    {
      "key": "world.nv7.return_channel_seen",
      "op": "set",
      "value": true
    }
  ]
}
```

## 节点 `s01_002`

```json
{
  "node_id": "s01_002",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "不是耳机里的提示音，也不是电脑散热的风声。一种低沉、持续、仿佛从石头内部传出来的嗡鸣贴着耳骨震动。"
  ],
  "next": "s01_003"
}
```

## 节点 `s01_003`

```json
{
  "node_id": "s01_003",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月睁开眼。"
  ],
  "next": "s01_004"
}
```

## 节点 `s01_004`

```json
{
  "node_id": "s01_004",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "灰白色石纹占满视野。他躺在一座圆形祭坛中央，晨雾正从石阶边缘缓慢漫过来。远处有鸡鸣，有木桶碰撞，有铁锤落在铁砧上的清脆回响。"
  ],
  "next": "s01_005"
}
```

## 节点 `s01_005`

```json
{
  "node_id": "s01_005",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "他没有立刻起身。"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "【角色：枫月】"
  ],
  "next": "s01_007"
}
```

## 节点 `s01_007`

```json
{
  "node_id": "s01_007",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "【等级：1】"
  ],
  "next": "s01_008"
}
```

## 节点 `s01_008`

```json
{
  "node_id": "s01_008",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "【区域：第七新手村·回响祭坛】"
  ],
  "next": "s01_009"
}
```

## 节点 `s01_009`

```json
{
  "node_id": "s01_009",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "【状态：轻度眩晕】"
  ],
  "next": "s01_010"
}
```

## 节点 `s01_010`

```json
{
  "node_id": "s01_010",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月盯着半透明界面。"
  ],
  "next": "s01_011"
}
```

## 节点 `s01_011`

```json
{
  "node_id": "s01_011",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "……这就是《王者》？"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "我连职业都还没选吧。"
  ],
  "next": "s01_013"
}
```

## 节点 `s01_013`

```json
{
  "node_id": "s01_013",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家取得第一次操作权。系统菜单开放：角色、背包、任务、设置、帮助。"
  ],
  "next": "s01_014"
}
```

## 节点 `s01_014`

```json
{
  "node_id": "s01_014",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "“退出游戏”所在的位置为空。"
  ],
  "next": "s01_choice_1"
}
```

## 节点 `s01_choice_1_1_response`

```json
{
  "node_id": "s01_choice_1_1_response",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月连续点了三次。没有按钮反馈。第四次时，空白处闪过一条极细的红线。",
    "枫月：“这里本来应该有东西。”"
  ],
  "next": "s01_016"
}
```

## 节点 `s01_choice_1_2_response`

```json
{
  "node_id": "s01_choice_1_2_response",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“退出游戏。”",
    "没有回应。",
    "枫月提高声音：“系统，退出《王者》。”",
    "远处的鸡叫了一声。",
    "枫月：“……很好。至少鸡听见了。”"
  ],
  "next": "s01_016"
}
```

## 节点 `s01_choice_1_3_response`

```json
{
  "node_id": "s01_choice_1_3_response",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "【连接状态：稳定】",
    "【延迟：不可测】",
    "【本地载体：已绑定】",
    "枫月：“本地载体？”",
    "他伸手触碰那一行字，界面立刻收缩。"
  ],
  "next": "s01_016"
}
```

## 节点 `s01_choice_1_4_response`

```json
{
  "node_id": "s01_choice_1_4_response",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "祭坛周围没有登录大厅，没有引导精灵，也没有其他刚创建角色的人。只有石阶下的一条土路通往村庄。",
    "枫月：“至少不是新手教学常见的样子。”"
  ],
  "next": "s01_016"
}
```

## 节点 `s01_choice_1`

```json
{
  "node_id": "s01_choice_1",
  "type": "choice",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice",
  "choices": [
    {
      "choice_id": "s01_choice_1_a1",
      "text": "点空白位置",
      "intent": "点空白位置",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s01_choice_1_1_response"
    },
    {
      "choice_id": "s01_choice_1_a2",
      "text": "呼叫系统",
      "intent": "呼叫系统",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s01_choice_1_2_response"
    },
    {
      "choice_id": "s01_choice_1_a3",
      "text": "检查连接状态",
      "intent": "检查连接状态",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s01_choice_1_3_response"
    },
    {
      "choice_id": "s01_choice_1_a4",
      "text": "先观察周围",
      "intent": "先观察周围",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s01_choice_1_4_response"
    }
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "无论玩家顺序如何，完成两项调查后触发："
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "【RETURN CHANNEL：LOCKED】"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "红色文字只停留两秒。"
  ],
  "next": "s01_019"
}
```

## 节点 `s01_019`

```json
{
  "node_id": "s01_019",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月立刻重新打开菜单。"
  ],
  "next": "s01_020"
}
```

## 节点 `s01_020`

```json
{
  "node_id": "s01_020",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "没有。"
  ],
  "next": "s01_021"
}
```

## 节点 `s01_021`

```json
{
  "node_id": "s01_021",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "锁住。"
  ],
  "next": "s01_022"
}
```

## 节点 `s01_022`

```json
{
  "node_id": "s01_022",
  "type": "dialogue",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "不是断开。"
  ],
  "next": "s01_023"
}
```

## 节点 `s01_023`

```json
{
  "node_id": "s01_023",
  "type": "narrative",
  "scene_id": "s01",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "[QuestManager: NV_MAIN_001 objective_01 complete]"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月撑着祭坛边缘站起来。"
  ],
  "next": "s02_002"
}
```

## 节点 `s02_002`

```json
{
  "node_id": "s02_002",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "双腿刚发力，一阵真实的眩晕猛地冲上来。他踩空一级石阶，膝盖磕在石沿上。"
  ],
  "next": "s02_003"
}
```

## 节点 `s02_003`

```json
{
  "node_id": "s02_003",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "嘶……"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "【状态提示：轻微擦伤】"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "他低头。裤腿没有破，膝盖却确实传来钝痛。"
  ],
  "next": "s02_choice_2"
}
```

## 节点 `s02_choice_2_1_response`

```json
{
  "node_id": "s02_choice_2_1_response",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月拧住自己小臂内侧。",
    "枫月：“疼。”",
    "他松手，看着皮肤慢慢泛红。",
    "枫月：“结论很充分，不需要复现。”"
  ],
  "next": "s02_007"
}
```

## 节点 `s02_choice_2_2_response`

```json
{
  "node_id": "s02_choice_2_2_response",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "指甲划过皮肤，刺痛和摩擦感都过于清晰。",
    "枫月：“触觉模拟能做到这种程度？”",
    "他没有继续用力。"
  ],
  "next": "s02_007"
}
```

## 节点 `s02_choice_2_3_response`

```json
{
  "node_id": "s02_choice_2_3_response",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月揉了揉膝盖。",
    "枫月：“已经够真实了。没必要为了证明刀会伤人，先给自己一刀。”"
  ],
  "next": "s02_007"
}
```

## 节点 `s02_choice_2`

```json
{
  "node_id": "s02_choice_2",
  "type": "choice",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice",
  "choices": [
    {
      "choice_id": "s02_choice_2_b1",
      "text": "掐一下手臂",
      "intent": "掐一下手臂",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s02_choice_2_1_response"
    },
    {
      "choice_id": "s02_choice_2_b2",
      "text": "用指甲轻划",
      "intent": "用指甲轻划",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s02_choice_2_2_response"
    },
    {
      "choice_id": "s02_choice_2_b3",
      "text": "不再测试",
      "intent": "不再测试",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s02_choice_2_3_response"
    }
  ],
  "next": "s02_007"
}
```

## 节点 `s02_007`

```json
{
  "node_id": "s02_007",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "三项都不改变长期状态，只改变稍后苏芷的首句对白版本。"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月再次迈下石阶，脚下却因为眩晕一软。"
  ],
  "next": "s02_009"
}
```

## 节点 `s02_009`

```json
{
  "node_id": "s02_009",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "一根木杖横过来，稳稳挡住他的肩。"
  ],
  "next": "s02_010"
}
```

## 节点 `s02_010`

```json
{
  "node_id": "s02_010",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "顾长川从雾中走出"
  ],
  "next": "s02_011"
}
```

## 节点 `s02_011`

```json
{
  "node_id": "s02_011",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "第一次从回响祭坛下来的人，都觉得自己的腿还是系统借给他的。"
  ],
  "next": "s02_012"
}
```

## 节点 `s02_012`

```json
{
  "node_id": "s02_012",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月站稳，退开半步。"
  ],
  "next": "s02_013"
}
```

## 节点 `s02_013`

```json
{
  "node_id": "s02_013",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你是谁？"
  ],
  "next": "s02_014"
}
```

## 节点 `s02_014`

```json
{
  "node_id": "s02_014",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "顾长川。这里的人叫我村长。"
  ],
  "next": "s02_015"
}
```

## 节点 `s02_015`

```json
{
  "node_id": "s02_015",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "这里是什么地方？"
  ],
  "next": "s02_016"
}
```

## 节点 `s02_016`

```json
{
  "node_id": "s02_016",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "第七新手村。"
  ],
  "next": "s02_017"
}
```

## 节点 `s02_017`

```json
{
  "node_id": "s02_017",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "我问的不是地图名字。"
  ],
  "next": "s02_018"
}
```

## 节点 `s02_018`

```json
{
  "node_id": "s02_018",
  "type": "narrative",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "顾长川看了他两秒。"
  ],
  "next": "s02_019"
}
```

## 节点 `s02_019`

```json
{
  "node_id": "s02_019",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "那你的问题太大。"
  ],
  "next": "s02_020"
}
```

## 节点 `s02_020`

```json
{
  "node_id": "s02_020",
  "type": "dialogue",
  "scene_id": "s02",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "我这个村长答不起。"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "顾长川没有追问枫月为什么从祭坛出现，只看了看他身边浮着的淡蓝色冒险者标记。"
  ],
  "next": "s03_choice_3"
}
```

## 节点 `s03_choice_3_1_response`

```json
{
  "node_id": "s03_choice_3_1_response",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“我不是这里的人。我来自现实世界。”",
    "顾长川：“现实世界。”",
    "他重复了一遍，语气像在记一个陌生地名。",
    "顾长川：“你们冒险者说过这个词。”",
    "枫月：“你们？”",
    "顾长川：“你不是第一批从祭坛下来的人。”",
    "枫月：“他们也说自己来自现实？”",
    "顾长川：“有人说城市，有人说公司，有人说自己本来应该去上班。”",
    "枫月：“他们回去了吗？”",
    "顾长川沉默。",
    "顾长川：“有人离开了这个村子。”",
    "枫月：“我问的不是村子。”",
    "顾长川：“那我不知道。”"
  ],
  "next": "s03_003",
  "relationship_actions": [
    {
      "relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN",
      "dimension": "trust",
      "op": "inc",
      "value": 1
    },
    {
      "relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN",
      "action": "set_flag",
      "flag_id": "remembers_fengyue_candor",
      "value": true
    }
  ]
}
```

## 节点 `s03_choice_3_2_response`

```json
{
  "node_id": "s03_choice_3_2_response",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“我不记得自己怎么到这里。”",
    "顾长川：“不记得？”",
    "枫月：“嗯。”",
    "顾长川看向枫月刚刚关闭的菜单位置。",
    "顾长川：“你看那块空地方的眼神，不像什么都不记得。”",
    "枫月：“村长都这么爱拆穿新人？”",
    "顾长川：“只拆穿会害死人的谎。”",
    "枫月：“这个还不至于。”",
    "顾长川：“那就等你觉得至于的时候再说。”"
  ],
  "next": "s03_003",
  "relationship_actions": [
    {
      "relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN",
      "dimension": "tension",
      "op": "inc",
      "value": 1
    },
    {
      "relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN",
      "action": "set_flag",
      "flag_id": "cautious_about_fengyue",
      "value": true
    }
  ]
}
```

## 节点 `s03_choice_3_3_response`

```json
{
  "node_id": "s03_choice_3_3_response",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice_response",
  "text": [
    "枫月：“你刚才说‘第一次下来的人’。以前还有别人？”",
    "顾长川：“有。”",
    "枫月：“很多？”",
    "顾长川：“最近这段时间，分了几批。”",
    "枫月：“他们现在在哪？”",
    "顾长川：“有人还在附近，有人已经去了更大的城。”",
    "枫月：“他们能退出吗？”",
    "顾长川：“退出什么？”",
    "枫月看着他，没有继续解释。",
    "顾长川：“你们冒险者经常说一些我们听得见，却不知道指向哪里的词。”"
  ],
  "next": "s03_003",
  "relationship_actions": [
    {
      "relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN",
      "dimension": "tension",
      "op": "inc",
      "value": 1
    }
  ]
}
```

## 节点 `s03_choice_3`

```json
{
  "node_id": "s03_choice_3",
  "type": "choice",
  "scene_id": "s03",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_choice",
  "choices": [
    {
      "choice_id": "s03_choice_3_c1",
      "text": "坦白——我来自现实世界。",
      "intent": "坦白——我来自现实世界。",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s03_choice_3_1_response"
    },
    {
      "choice_id": "s03_choice_3_c2",
      "text": "隐瞒——我不记得怎么来的。",
      "intent": "隐瞒——我不记得怎么来的。",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s03_choice_3_2_response"
    },
    {
      "choice_id": "s03_choice_3_c3",
      "text": "试探——以前还有人从这里醒过？",
      "intent": "试探——以前还有人从这里醒过？",
      "protagonist_boundary": "allowed",
      "visible_risk": "可见后果见选项文本",
      "consequence_summary": "进入审核稿声明的对应回应",
      "hidden_consequence": "无额外隐藏改写",
      "conditions": [],
      "effects": [],
      "goto": "s03_choice_3_3_response"
    }
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "我听不懂你们说的现实，也不会装作听懂。"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "但你不是第一个问‘怎么回去’的人。"
  ],
  "next": "s03_005"
}
```

## 节点 `s03_005`

```json
{
  "node_id": "s03_005",
  "type": "narrative",
  "scene_id": "s03",
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月的表情第一次真正沉下来。"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "这句话比任何答案都糟。"
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
  "location_id": "NV7_LOC_ALTAR",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "至少它是真的。"
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
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "顾长川递来一只粗陶水壶。"
  ],
  "next": "s04_002"
}
```

## 节点 `s04_002`

```json
{
  "node_id": "s04_002",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月接住水壶，手腕明显下沉"
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
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "挺重。"
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
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "里面装的是水，不是图标。"
  ],
  "next": "s04_005"
}
```

## 节点 `s04_005`

```json
{
  "node_id": "s04_005",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月拔开木塞，水带着井里的凉意。"
  ],
  "next": "s04_006"
}
```

## 节点 `s04_006`

```json
{
  "node_id": "s04_006",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "喝下去后，喉咙的干涩明显缓解。"
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
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "【口渴状态解除】"
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
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "连口渴都算状态？"
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
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "你们冒险者喜欢把事情叫成状态。"
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
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "我们一般叫渴。"
  ],
  "next": "s04_011"
}
```

## 节点 `s04_011`

```json
{
  "node_id": "s04_011",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "两人沿土路向村内走。"
  ],
  "next": "s04_012"
}
```

## 节点 `s04_012`

```json
{
  "node_id": "s04_012",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "你可以把我们当任务。"
  ],
  "next": "s04_013"
}
```

## 节点 `s04_013`

```json
{
  "node_id": "s04_013",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月看向他。"
  ],
  "next": "s04_014"
}
```

## 节点 `s04_014`

```json
{
  "node_id": "s04_014",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "把狼当经验。"
  ],
  "next": "s04_015"
}
```

## 节点 `s04_015`

```json
{
  "node_id": "s04_015",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "“把药草当材料。”"
  ],
  "next": "s04_016"
}
```

## 节点 `s04_016`

```json
{
  "node_id": "s04_016",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你是在提醒我别这么做？"
  ],
  "next": "s04_017"
}
```

## 节点 `s04_017`

```json
{
  "node_id": "s04_017",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "不是。"
  ],
  "next": "s04_018"
}
```

## 节点 `s04_018`

```json
{
  "node_id": "s04_018",
  "type": "narrative",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_narrative",
  "text": [
    "顾长川停下，用木杖点了点路边一块被啃坏的木牌。"
  ],
  "next": "s04_019"
}
```

## 节点 `s04_019`

```json
{
  "node_id": "s04_019",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "我是提醒你，任务做砸了，会有人替你收拾残局。"
  ],
  "next": "s04_020"
}
```

## 节点 `s04_020`

```json
{
  "node_id": "s04_020",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "狼没杀干净，会去咬别的人。"
  ],
  "next": "s04_021"
}
```

## 节点 `s04_021`

```json
{
  "node_id": "s04_021",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "药草拔光了，明年就没有药。"
  ],
  "next": "s04_022"
}
```

## 节点 `s04_022`

```json
{
  "node_id": "s04_022",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "那系统呢？"
  ],
  "next": "s04_023"
}
```

## 节点 `s04_023`

```json
{
  "node_id": "s04_023",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "系统会告诉你完成没完成。"
  ],
  "next": "s04_024"
}
```

## 节点 `s04_024`

```json
{
  "node_id": "s04_024",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "不会替你把后果擦掉。"
  ],
  "next": "s04_025"
}
```

## 节点 `s04_025`

```json
{
  "node_id": "s04_025",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "听起来不像游戏。"
  ],
  "next": "s04_026"
}
```

## 节点 `s04_026`

```json
{
  "node_id": "s04_026",
  "type": "dialogue",
  "scene_id": "s04",
  "location_id": "NV7_LOC_FIELDS",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "你们每一批冒险者都有人说这句话。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "顾长川带枫月在告示板前停下。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "他从腰间取下一块空白木牌。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "村里不能让一个什么都没有的冒险者直接往外跑。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "你先替村里做三件事。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "系统展开三份委托："
  ],
  "next": "s05_006"
}
```

## 节点 `s05_006`

```json
{
  "node_id": "s05_006",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "韩石：试刃与黑铁碎片"
  ],
  "next": "s05_007"
}
```

## 节点 `s05_007`

```json
{
  "node_id": "s05_007",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "苏芷：药篮与北坡采集"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "顾长川：北界石巡检"
  ],
  "next": "s05_009"
}
```

## 节点 `s05_009`

```json
{
  "node_id": "s05_009",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "三件都要做？"
  ],
  "next": "s05_010"
}
```

## 节点 `s05_010`

```json
{
  "node_id": "s05_010",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "做两件，我给你临时通行权限。"
  ],
  "next": "s05_011"
}
```

## 节点 `s05_011`

```json
{
  "node_id": "s05_011",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "第三件呢？"
  ],
  "next": "s05_012"
}
```

## 节点 `s05_012`

```json
{
  "node_id": "s05_012",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "你愿意做就做。"
  ],
  "next": "s05_013"
}
```

## 节点 `s05_013`

```json
{
  "node_id": "s05_013",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "如果一件都不做？"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "也可以。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "真的？"
  ],
  "next": "s05_016"
}
```

## 节点 `s05_016`

```json
{
  "node_id": "s05_016",
  "type": "narrative",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "顾长川用木杖指了指村外。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "狼也可以自由决定吃不吃你。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月看了村口一眼。"
  ],
  "next": "s05_019"
}
```

## 节点 `s05_019`

```json
{
  "node_id": "s05_019",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "你的欢迎仪式挺朴素。"
  ],
  "next": "s05_020"
}
```

## 节点 `s05_020`

```json
{
  "node_id": "s05_020",
  "type": "dialogue",
  "scene_id": "s05",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "能记住就行。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "NV_MAIN_001 完成"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "解锁 NV_MAIN_002"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "解锁三个并行子目标"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "奖励结算：由 QuestManager 幂等发放基础新手币与临时通行牌“申请资格”，不是物品布尔状态。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "玩家在离开广场前再次开启系统菜单。"
  ],
  "next": "s06_002"
}
```

## 节点 `s06_002`

```json
{
  "node_id": "s06_002",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "【WORLD CONNECTION：STABLE】"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "【LOCAL BODY：BOUND】"
  ],
  "next": "s06_004"
}
```

## 节点 `s06_004`

```json
{
  "node_id": "s06_004",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "【RETURN CHANNEL：LOCKED】"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "【LOCK AUTHORITY：UNKNOWN】"
  ],
  "next": "s06_006"
}
```

## 节点 `s06_006`

```json
{
  "node_id": "s06_006",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "枫月盯着最后一行。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "权限。"
  ],
  "next": "s06_008"
}
```

## 节点 `s06_008`

```json
{
  "node_id": "s06_008",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "所以不是坏了。"
  ],
  "next": "s06_009"
}
```

## 节点 `s06_009`

```json
{
  "node_id": "s06_009",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "是有人，或者某种规则，不让我用。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "他关掉菜单。"
  ],
  "next": "s06_011"
}
```

## 节点 `s06_011`

```json
{
  "node_id": "s06_011",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "先活下来。"
  ],
  "next": "s06_012"
}
```

## 节点 `s06_012`

```json
{
  "node_id": "s06_012",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "再找钥匙。"
  ],
  "next": "s06_013"
}
```

## 节点 `s06_013`

```json
{
  "node_id": "s06_013",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "本任务无正式战斗。若玩家反复冲撞村口结界："
  ],
  "next": "s06_014"
}
```

## 节点 `s06_014`

```json
{
  "node_id": "s06_014",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "【区域出口尚未取得授权】"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "薄雾将枫月送回村内。"
  ],
  "next": "s06_016"
}
```

## 节点 `s06_016`

```json
{
  "node_id": "s06_016",
  "type": "narrative",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "第三次以后顾长川追加："
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "你要是想测试结界，至少换个角度。"
  ],
  "next": "s06_018"
}
```

## 节点 `s06_018`

```json
{
  "node_id": "s06_018",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "PROTAGONIST_FENGYUE",
  "expression": "neutral",
  "portrait_action": "hide",
  "text": [
    "有区别？"
  ],
  "next": "s06_019"
}
```

## 节点 `s06_019`

```json
{
  "node_id": "s06_019",
  "type": "dialogue",
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_dialogue",
  "speaker_id": "NV7_NPC_CHIEF",
  "expression": "calm",
  "portrait_action": "show",
  "text": [
    "没有。我只是怕你撞同一棵树上。"
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
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "reviewed_narrative",
  "text": [
    "不改变任务状态。"
  ],
  "quest_actions": [
    {
      "action": "update_objective",
      "quest_id": "NV_MAIN_001",
      "objective_id": "arrival",
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
  "scene_id": "s06",
  "location_id": "NV7_LOC_SQUARE",
  "purpose": "r1_story_complete",
  "terminal": true,
  "outcome": "nv_main_001_complete",
  "next_story_id": "NV_MAIN_002"
}
```
