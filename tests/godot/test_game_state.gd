extends SceneTree

const GameStateClass = preload("res://src/core/game_state.gd")
const FIXTURE_PATH := "res://content/tests/fixtures/game_state/state_registry.json"

class FixtureLoader extends RefCounted:
    var definitions: Array

    func _init(value: Array) -> void:
        definitions = value

    func get_state_definitions() -> Array:
        return definitions.duplicate(true)


var _failures: Array[String] = []
var _events: Array[Dictionary] = []


func _init() -> void:
    var game_state: RefCounted = _new_game_state()
    if game_state == null:
        quit(1)
        return

    _test_defaults_and_basic_writes(game_state)
    _test_conditions(game_state)
    _test_atomic_batches(game_state)
    _test_signals(game_state)
    _test_snapshots(game_state)
    _test_resets(game_state)
    _test_access_protection(game_state)

    if _failures.is_empty():
        print("GAME_STATE_TESTS_OK")
        quit(0)
        return
    for failure: String in _failures:
        printerr("GAME_STATE_TEST_FAILURE:%s" % failure)
    quit(1)


func _new_game_state() -> RefCounted:
    var file := FileAccess.open(FIXTURE_PATH, FileAccess.READ)
    if file == null:
        _failures.append("无法读取GameState测试夹具")
        return null
    var document: Variant = JSON.parse_string(file.get_as_text())
    if not document is Dictionary or not document.get("states") is Array:
        _failures.append("GameState测试夹具不是有效JSON")
        return null
    var game_state := GameStateClass.new()
    if not game_state.initialize_from_content_loader(FixtureLoader.new(document["states"])):
        _failures.append("无法从ContentLoader状态注册表初始化")
        return null
    game_state.state_changed.connect(_on_state_changed)
    return game_state


func _test_defaults_and_basic_writes(game_state: RefCounted) -> void:
    _expect(game_state.get_state_count() == 6, "默认状态数量错误")
    _expect(game_state.get_state("test.counter") == 2, "默认整数状态错误")
    _expect(game_state.get_state("test.mode") == "idle", "默认枚举状态错误")
    _expect(game_state.set_state("test.counter", 4, "debug"), "合法set失败")
    _expect(game_state.get_state("test.counter") == 4, "合法set未生效")
    _expect(not game_state.set_state("test.counter", "4", "debug"), "非法类型被接受")
    _expect(game_state.get_state("test.counter") == 4, "非法类型污染了状态")
    _expect(not game_state.set_state("test.unknown", 1, "debug"), "未知键被创建")
    _expect(not game_state.has_state("test.unknown"), "未知键出现在注册表")
    _expect(game_state.inc_state("test.counter", 3, "debug"), "inc失败")
    _expect(game_state.dec_state("test.counter", 2, "debug"), "dec失败")
    _expect(game_state.get_state("test.counter") == 5, "inc/dec结果错误")
    _expect(not game_state.inc_state("test.counter", 6, "debug"), "超上限写入被接受")
    _expect(game_state.get_state("test.counter") == 5, "超上限写入污染了状态")
    _expect(not game_state.dec_state("test.counter", 6, "debug"), "低于下限写入被接受")
    _expect(not game_state.set_state("test.mode", "unknown", "debug"), "非法枚举值被接受")
    _expect(game_state.get_state("test.mode") == "idle", "非法枚举值污染了状态")


func _test_conditions(game_state: RefCounted) -> void:
    _expect(game_state.evaluate_condition({"key": "test.counter", "op": "eq", "value": 5}), "eq错误")
    _expect(game_state.evaluate_condition({"key": "test.counter", "op": "neq", "value": 4}), "neq错误")
    _expect(game_state.evaluate_condition({"key": "test.counter", "op": "gt", "value": 4}), "gt错误")
    _expect(game_state.evaluate_condition({"key": "test.counter", "op": "gte", "value": 5}), "gte错误")
    _expect(game_state.evaluate_condition({"key": "test.counter", "op": "lt", "value": 6}), "lt错误")
    _expect(game_state.evaluate_condition({"key": "test.counter", "op": "lte", "value": 5}), "lte错误")
    _expect(game_state.evaluate_condition({"key": "test.counter", "op": "in", "value": [4, 5]}), "in错误")
    _expect(game_state.evaluate_condition({"key": "test.counter", "op": "not_in", "value": [1, 2]}), "not_in错误")


func _test_atomic_batches(game_state: RefCounted) -> void:
    _expect(game_state.apply_effects([
        {"op": "inc", "key": "test.counter", "value": 1},
        {"op": "set", "key": "test.mode", "value": "active"},
    ], "story"), "合法批量修改失败")
    _expect(game_state.get_state("test.counter") == 6 and game_state.get_state("test.mode") == "active", "合法批量结果错误")
    var before: Dictionary = game_state.export_snapshot()
    _expect(not game_state.apply_effects([
        {"op": "set", "key": "test.counter", "value": 7},
        {"op": "set", "key": "test.mode", "value": "invalid"},
    ], "story"), "含非法项的批量修改成功")
    _expect(game_state.export_snapshot() == before, "失败批次没有完整回滚")


func _test_signals(game_state: RefCounted) -> void:
    _events.clear()
    _expect(game_state.set_state("test.counter", 6, "debug"), "同值写入失败")
    _expect(_events.is_empty(), "同值写入错误触发信号")
    _expect(game_state.set_state("test.counter", 7, "debug"), "信号测试写入失败")
    _expect(_events.size() == 1, "实际变化没有且仅触发一次信号")
    if _events.size() == 1:
        _expect(_events[0] == {"key": "test.counter", "old_value": 6, "new_value": 7, "source": "debug"}, "信号字段错误")


func _test_snapshots(game_state: RefCounted) -> void:
    var snapshot: Dictionary = game_state.export_snapshot()
    _expect(not snapshot.has("test.note"), "快照包含非持久状态")
    _expect(game_state.set_state("test.counter", 1, "debug"), "快照测试修改失败")
    _expect(game_state.set_state("test.note", "temporary", "debug"), "非持久状态修改失败")
    _expect(game_state.restore_snapshot(snapshot), "合法快照恢复失败")
    _expect(game_state.export_snapshot() == snapshot, "快照恢复后不一致")
    _expect(game_state.get_state("test.note") == "", "快照恢复未重置非持久状态")

    _expect(game_state.set_state("test.counter", 8, "debug"), "非法快照前置修改失败")
    var before: Dictionary = game_state.export_snapshot()
    var invalid: Dictionary = before.duplicate(true)
    invalid["test.counter"] = "bad"
    _expect(not game_state.restore_snapshot(invalid), "非法快照恢复成功")
    _expect(game_state.export_snapshot() == before, "非法快照污染当前状态")


func _test_resets(game_state: RefCounted) -> void:
    _expect(game_state.reset_state("test.counter", "system"), "reset_state失败")
    _expect(game_state.get_state("test.counter") == 2, "reset_state未恢复默认值")
    _expect(game_state.set_state("test.mode", "paused", "debug"), "reset_all前置修改失败")
    _expect(game_state.set_state("test.flag", true, "debug"), "reset_all前置布尔修改失败")
    _expect(game_state.reset_all_states("system"), "reset_all_states失败")
    _expect(game_state.get_state("test.counter") == 2, "reset_all整数默认值错误")
    _expect(game_state.get_state("test.mode") == "idle", "reset_all枚举默认值错误")
    _expect(game_state.get_state("test.flag") == false, "reset_all布尔默认值错误")


func _test_access_protection(game_state: RefCounted) -> void:
    _expect(not game_state.set_state("test.read_only", false, "debug"), "外部来源修改了只读状态")
    _expect(game_state.get_state("test.read_only") == true, "只读状态被污染")
    _expect(not game_state.set_state("test.restricted", 1, "story"), "未授权来源修改了受限状态")
    _expect(game_state.set_state("test.restricted", 1, "combat"), "授权来源无法修改受限状态")


func _on_state_changed(key: String, old_value: Variant, new_value: Variant, source: String) -> void:
    _events.append({"key": key, "old_value": old_value, "new_value": new_value, "source": source})


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
