extends RefCounted

const ENUM_NAMES := {
    "trust": "信任", "affection": "好感", "respect": "尊重", "tension": "紧张",
    "stranger": "陌生", "acquaintance": "相识", "trusted": "信赖", "close": "亲近", "intimate": "亲密",
    "not_started": "未开始", "available": "可接取", "active": "进行中", "qualified": "已满足推进条件",
    "completed": "已完成", "failed": "失败", "suspended": "暂停",
    "weapon": "武器", "offhand": "副手", "off_hand": "副手", "head": "头部", "body": "身体",
    "accessory_1": "饰品一", "accessory_2": "饰品二",
    "consumable": "消耗品", "equipment": "装备", "quest": "任务物品", "material": "材料", "key_item": "关键物品",
    "player": "玩家", "ally": "同伴", "companion": "同伴", "enemy": "敌人",
    "attack": "攻击", "defend": "防御", "skill": "技能", "item": "物品", "inspect": "观察", "retreat": "撤退",
    "guard": "防御", "stun": "眩晕", "marked": "标记", "poison": "中毒", "defense_down": "防御降低",
    "manual_1": "手动存档一", "manual_2": "手动存档二", "manual_3": "手动存档三", "auto": "自动存档", "quick": "快速存档",
    "both": "战斗与探索", "battle_only": "仅战斗", "field_only": "仅探索",
}

var _content_loader: RefCounted


func bind_content_loader(content_loader: RefCounted) -> void:
    _content_loader = content_loader


func enum_name(value: String, fallback: String = "未知状态") -> String:
    if ENUM_NAMES.has(value):
        return str(ENUM_NAMES[value])
    if not value.is_empty() and OS.is_debug_build():
        print("DISPLAY_NAME_MISSING enum=%s" % value)
    return fallback


func content_name(global_id: String, fallback: String = "未知内容") -> String:
    if global_id.is_empty():
        return fallback
    if _content_loader != null:
        var definition: Variant = _content_loader.call("get_by_id", global_id)
        if definition is Dictionary:
            for field: String in ["display_name", "name", "title"]:
                var value := str(definition.get(field, "")).strip_edges()
                if not value.is_empty() and value != global_id:
                    return value
    if OS.is_debug_build():
        print("DISPLAY_NAME_MISSING id=%s" % global_id)
    return fallback


func location_name(location_id: String) -> String:
    return "—" if location_id.is_empty() else content_name(location_id, "未知地点")


func relationship_name(definition: Dictionary, relationship_id: String) -> String:
    for field: String in ["display_name", "name", "title"]:
        var value := str(definition.get(field, "")).strip_edges()
        if not value.is_empty() and value != relationship_id:
            return value
    for field: String in ["target_id", "npc_id", "character_id"]:
        var target_id := str(definition.get(field, ""))
        if not target_id.is_empty():
            return content_name(target_id, "未知角色")
    return "未知角色"


func bool_name(value: bool) -> String:
    return "开启" if value else "关闭"
