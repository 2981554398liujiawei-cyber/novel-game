extends RefCounted

signal state_changed(key: String, old_value: Variant, new_value: Variant, source: String)
signal state_error(error: Dictionary)

const INTERNAL_SOURCES := ["system", "save_restore"]
const SUPPORTED_TYPES := ["string", "integer", "number", "boolean"]
const SUPPORTED_EFFECTS := ["set", "inc", "dec"]
const SUPPORTED_CONDITIONS := ["eq", "neq", "ne", "gt", "gte", "lt", "lte", "in", "not_in"]

var last_error: Dictionary = {}

var _definitions: Dictionary = {}
var _values: Dictionary = {}
var _initialized := false


func initialize_from_content_loader(content_loader: RefCounted) -> bool:
    last_error = {}
    if content_loader == null or not content_loader.has_method("get_state_definitions"):
        return _fail("STATE_REGISTRY_UNAVAILABLE", "ContentLoader does not provide a state registry")

    var raw_definitions: Variant = content_loader.call("get_state_definitions")
    if not raw_definitions is Array:
        return _fail("STATE_REGISTRY_INVALID", "State registry must be an array")

    var next_definitions := {}
    var next_values := {}
    for raw_definition: Variant in raw_definitions:
        if not raw_definition is Dictionary:
            return _fail("STATE_DEFINITION_INVALID", "Every state definition must be an object")
        var definition: Dictionary = raw_definition
        var key := str(definition.get("key", ""))
        if key.is_empty():
            return _fail("STATE_DEFINITION_INVALID", "State key cannot be empty")
        if next_definitions.has(key):
            return _fail("DUPLICATE_STATE_KEY", "Duplicate state key '%s'" % key, key)
        if not _validate_definition(definition, key):
            return false
        next_definitions[key] = definition.duplicate(true)
        next_values[key] = _normalize_value(definition["default"], definition)

    _definitions = next_definitions
    _values = next_values
    _initialized = true
    return true


func is_initialized() -> bool:
    return _initialized


func get_state_count() -> int:
    return _definitions.size()


func has_state(key: String) -> bool:
    return _definitions.has(key)


func get_state(key: String) -> Variant:
    if not _require_key(key):
        return null
    return _copy_value(_values[key])


func set_state(key: String, value: Variant, source: String = "system") -> bool:
    return apply_effects([{"op": "set", "key": key, "value": value}], source)


func inc_state(key: String, value: Variant, source: String = "system") -> bool:
    return apply_effects([{"op": "inc", "key": key, "value": value}], source)


func dec_state(key: String, value: Variant, source: String = "system") -> bool:
    return apply_effects([{"op": "dec", "key": key, "value": value}], source)


func reset_state(key: String, source: String = "system") -> bool:
    if not _require_key(key):
        return false
    return set_state(key, _definitions[key]["default"], source)


func reset_all_states(source: String = "system") -> bool:
    var effects: Array = []
    for key: Variant in _definitions.keys():
        effects.append({"op": "set", "key": key, "value": _definitions[key]["default"]})
    return apply_effects(effects, source)


func apply_effects(effects: Array, source: String = "system") -> bool:
    last_error = {}
    if not _require_initialized() or not _validate_source(source):
        return false

    var staged: Dictionary = _values.duplicate(true)
    var original_values := {}
    var changed_order: Array[String] = []

    for raw_effect: Variant in effects:
        if not raw_effect is Dictionary:
            return _fail("STATE_EFFECT_INVALID", "Every state effect must be an object")
        var effect: Dictionary = raw_effect
        var operation := str(effect.get("op", ""))
        var key := str(effect.get("key", ""))
        if operation not in SUPPORTED_EFFECTS:
            return _fail("STATE_EFFECT_INVALID", "Unsupported state effect '%s'" % operation, key)
        if not _require_key(key) or not _can_write(key, source):
            return false
        if not effect.has("value"):
            return _fail("STATE_EFFECT_INVALID", "State effect is missing value", key)

        var next_value: Variant = effect["value"]
        if operation == "inc" or operation == "dec":
            if not _is_numeric_state(key):
                return _fail("STATE_EFFECT_INVALID", "%s is only valid for numeric states" % operation, key)
            if not _is_number(next_value):
                return _fail("STATE_TYPE_INVALID", "Numeric effect value must be a number", key)
            next_value = staged[key] + next_value if operation == "inc" else staged[key] - next_value

        if not _validate_value(key, next_value):
            return false
        if not original_values.has(key):
            original_values[key] = _copy_value(_values[key])
            changed_order.append(key)
        staged[key] = _normalize_value(next_value, _definitions[key])

    _values = staged
    for key: String in changed_order:
        var old_value: Variant = original_values[key]
        var new_value: Variant = _values[key]
        if old_value != new_value:
            state_changed.emit(key, _copy_value(old_value), _copy_value(new_value), source)
    return true


func evaluate_condition(condition: Dictionary) -> bool:
    last_error = {}
    if not _require_initialized():
        return false
    var key := str(condition.get("key", ""))
    var operation := str(condition.get("op", ""))
    if not _require_key(key):
        return false
    if operation not in SUPPORTED_CONDITIONS:
        return _fail("STATE_CONDITION_INVALID", "Unsupported state condition '%s'" % operation, key)
    if not condition.has("value"):
        return _fail("STATE_CONDITION_INVALID", "State condition is missing value", key)

    var current: Variant = _values[key]
    var expected: Variant = condition["value"]
    match operation:
        "eq":
            return current == expected
        "neq", "ne":
            return current != expected
        "gt", "gte", "lt", "lte":
            if not _is_number(current) or not _is_number(expected):
                return _fail("STATE_CONDITION_INVALID", "%s requires numeric values" % operation, key)
            if operation == "gt":
                return current > expected
            if operation == "gte":
                return current >= expected
            if operation == "lt":
                return current < expected
            return current <= expected
        "in", "not_in":
            if not expected is Array:
                return _fail("STATE_CONDITION_INVALID", "%s requires an array value" % operation, key)
            var contains: bool = current in expected
            return contains if operation == "in" else not contains
    return false


func export_snapshot() -> Dictionary:
    var snapshot := {}
    if not _require_initialized():
        return snapshot
    for key: Variant in _definitions.keys():
        if bool(_definitions[key].get("persistent", false)):
            snapshot[key] = _copy_value(_values[key])
    return snapshot


func validate_snapshot(snapshot: Dictionary) -> bool:
    last_error = {}
    if not _require_initialized():
        return false
    return _validate_snapshot_data(snapshot)


func create_runtime_checkpoint() -> Dictionary:
    last_error = {}
    if not _require_initialized():
        return {}
    return _values.duplicate(true)


func restore_runtime_checkpoint(checkpoint: Dictionary) -> bool:
    last_error = {}
    if not _require_initialized() or not _validate_runtime_checkpoint(checkpoint):
        return false
    var staged := {}
    for raw_key: Variant in _definitions.keys():
        var key := str(raw_key)
        staged[key] = _normalize_value(checkpoint[key], _definitions[key])
    _values = staged
    return true


func emit_changes_from_checkpoint(checkpoint: Dictionary, source: String = "save_restore") -> bool:
    last_error = {}
    if not _require_initialized() or not _validate_source(source) or not _validate_runtime_checkpoint(checkpoint):
        return false
    var committed_values: Dictionary = _values.duplicate(true)
    for raw_key: Variant in _definitions.keys():
        var key := str(raw_key)
        if checkpoint[key] != committed_values[key]:
            state_changed.emit(
                key,
                _copy_value(checkpoint[key]),
                _copy_value(committed_values[key]),
                source,
            )
    return true


func restore_snapshot(snapshot: Dictionary, source: String = "save_restore") -> bool:
    last_error = {}
    if not _require_initialized() or not _validate_source(source):
        return false
    if not _validate_snapshot_data(snapshot):
        return false

    var staged := {}
    for raw_key: Variant in _definitions.keys():
        var key := str(raw_key)
        var definition: Dictionary = _definitions[key]
        if bool(definition.get("persistent", false)):
            if not _can_write(key, source):
                return false
            staged[key] = _normalize_value(snapshot[key], definition)
        else:
            staged[key] = _normalize_value(definition["default"], definition)

    var previous: Dictionary = _values
    _values = staged
    for key: Variant in _definitions.keys():
        if previous[key] != _values[key]:
            state_changed.emit(str(key), _copy_value(previous[key]), _copy_value(_values[key]), source)
    return true


func _validate_snapshot_data(snapshot: Dictionary) -> bool:
    for raw_key: Variant in snapshot.keys():
        var key := str(raw_key)
        if not _require_key(key):
            return false
        if not bool(_definitions[key].get("persistent", false)):
            return _fail("STATE_SNAPSHOT_INVALID", "Snapshot contains non-persistent state", key)

    for raw_key: Variant in _definitions.keys():
        var key := str(raw_key)
        if not bool(_definitions[key].get("persistent", false)):
            continue
        if not snapshot.has(key):
            return _fail("STATE_SNAPSHOT_INVALID", "Snapshot is missing persistent state", key)
        if not _validate_value(key, snapshot[key]):
            return false
    return true


func _validate_runtime_checkpoint(checkpoint: Dictionary) -> bool:
    if checkpoint.size() != _definitions.size():
        return _fail("STATE_CHECKPOINT_INVALID", "Runtime checkpoint has the wrong number of states")
    for raw_key: Variant in checkpoint.keys():
        var key := str(raw_key)
        if not _require_key(key):
            return false
    for raw_key: Variant in _definitions.keys():
        var key := str(raw_key)
        if not checkpoint.has(key):
            return _fail("STATE_CHECKPOINT_INVALID", "Runtime checkpoint is missing state", key)
        if not _validate_value(key, checkpoint[key]):
            return false
    return true


func _validate_definition(definition: Dictionary, key: String) -> bool:
    var type_name := str(definition.get("type", ""))
    if type_name not in SUPPORTED_TYPES or not definition.has("default") or not definition.has("persistent"):
        return _fail("STATE_DEFINITION_INVALID", "State definition is missing required metadata", key)
    if not definition["persistent"] is bool:
        return _fail("STATE_DEFINITION_INVALID", "State persistent must be boolean", key)
    if (definition.has("min") or definition.has("max")) and type_name not in ["integer", "number"]:
        return _fail("STATE_DEFINITION_INVALID", "Only numeric states may define minimum or maximum", key)
    if definition.has("min") and definition.has("max") and definition["min"] > definition["max"]:
        return _fail("STATE_DEFINITION_INVALID", "State minimum cannot exceed maximum", key)
    if definition.has("allowed") and not definition["allowed"] is Array:
        return _fail("STATE_DEFINITION_INVALID", "State allowed values must be an array", key)
    if definition.has("read_only") and not definition["read_only"] is bool:
        return _fail("STATE_DEFINITION_INVALID", "State read_only must be boolean", key)
    if definition.has("write_sources") and not definition["write_sources"] is Array:
        return _fail("STATE_DEFINITION_INVALID", "State write_sources must be an array", key)
    for source: Variant in definition.get("write_sources", []):
        if not source is String or source.strip_edges().is_empty():
            return _fail("STATE_DEFINITION_INVALID", "State write_sources must contain non-empty strings", key)
    return _validate_value_against_definition(key, definition["default"], definition)


func _validate_value(key: String, value: Variant) -> bool:
    return _validate_value_against_definition(key, value, _definitions[key])


func _validate_value_against_definition(key: String, value: Variant, definition: Dictionary) -> bool:
    var valid_type := false
    match str(definition["type"]):
        "string":
            valid_type = value is String
        "integer":
            valid_type = _is_integer_value(value)
        "number":
            valid_type = _is_number(value)
        "boolean":
            valid_type = value is bool
    if not valid_type:
        return _fail("STATE_TYPE_INVALID", "Value does not match registered type '%s'" % definition["type"], key)
    if definition.has("min") and value < definition["min"]:
        return _fail("STATE_RANGE_INVALID", "Value is below registered minimum", key)
    if definition.has("max") and value > definition["max"]:
        return _fail("STATE_RANGE_INVALID", "Value exceeds registered maximum", key)
    if definition.has("allowed") and value not in definition["allowed"]:
        return _fail("STATE_ENUM_INVALID", "Value is not in the registered allowed list", key)
    return true


func _can_write(key: String, source: String) -> bool:
    var definition: Dictionary = _definitions[key]
    if source in INTERNAL_SOURCES:
        return true
    if bool(definition.get("read_only", false)):
        return _fail("STATE_WRITE_FORBIDDEN", "State is read-only for external sources", key)
    var write_sources: Array = definition.get("write_sources", [])
    if not write_sources.is_empty() and source not in write_sources:
        return _fail("STATE_WRITE_FORBIDDEN", "Source '%s' cannot modify this state" % source, key)
    return true


func _is_numeric_state(key: String) -> bool:
    return str(_definitions[key]["type"]) in ["integer", "number"]


func _is_number(value: Variant) -> bool:
    return value is int or value is float


func _is_integer_value(value: Variant) -> bool:
    return value is int or (value is float and value == floor(value))


func _normalize_value(value: Variant, definition: Dictionary) -> Variant:
    if str(definition["type"]) == "integer" and value is float:
        return int(value)
    return _copy_value(value)


func _validate_source(source: String) -> bool:
    if source.strip_edges().is_empty():
        return _fail("STATE_SOURCE_INVALID", "State mutation source cannot be empty")
    return true


func _require_initialized() -> bool:
    if not _initialized:
        return _fail("GAME_STATE_NOT_INITIALIZED", "GameState has not been initialized")
    return true


func _require_key(key: String) -> bool:
    if not _initialized:
        return _require_initialized()
    if not _definitions.has(key):
        return _fail("UNKNOWN_STATE_KEY", "State key is not registered", key)
    return true


func _copy_value(value: Variant) -> Variant:
    if value is Dictionary or value is Array:
        return value.duplicate(true)
    return value


func _fail(code: String, message: String, key: String = "") -> bool:
    last_error = {"code": code, "message": message, "key": key}
    printerr("GAME_STATE_ERROR:%s:%s:%s" % [code, key, message])
    state_error.emit(last_error.duplicate(true))
    return false
