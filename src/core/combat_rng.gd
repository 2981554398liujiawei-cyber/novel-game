extends RefCounted

## Small deterministic generator used by CombatRunner.
## The 32-bit state is JSON-safe and produces identical sequences on every platform.

const UINT32_MASK := 0xFFFFFFFF
const UINT32_RANGE := 4294967296.0

var _seed := 0
var _state := 0
var _calls := 0


func initialize(seed_value: int) -> void:
    _seed = seed_value & UINT32_MASK
    _state = _seed
    _calls = 0


func next_u32() -> int:
    _state = (_state * 1664525 + 1013904223) & UINT32_MASK
    _calls += 1
    return _state


func next_float() -> float:
    return float(next_u32()) / UINT32_RANGE


func range_int(minimum: int, maximum: int) -> int:
    if maximum <= minimum:
        return minimum
    var span := maximum - minimum + 1
    return minimum + int(next_u32() % span)


func chance(probability: float) -> bool:
    return next_float() < clampf(probability, 0.0, 1.0)


func export_state() -> Dictionary:
    return {
        "seed": _seed,
        "state": _state,
        "calls": _calls,
    }


func restore_state(snapshot: Dictionary) -> bool:
    for key: String in ["seed", "state", "calls"]:
        if not snapshot.has(key) or not _is_integer_value(snapshot[key]):
            return false
    var seed_value := int(snapshot["seed"])
    var state_value := int(snapshot["state"])
    var calls_value := int(snapshot["calls"])
    if seed_value < 0 or seed_value > UINT32_MASK:
        return false
    if state_value < 0 or state_value > UINT32_MASK:
        return false
    if calls_value < 0:
        return false
    _seed = seed_value
    _state = state_value
    _calls = calls_value
    return true


func _is_integer_value(value: Variant) -> bool:
    return value is int or (value is float and is_equal_approx(value, floor(value)))
