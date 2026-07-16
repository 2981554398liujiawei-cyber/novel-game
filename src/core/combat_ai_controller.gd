extends RefCounted

const TENDENCIES := ["offensive", "defensive", "support"]


func build_weights(actions: Array, tendency: String, condition_filter: Callable) -> Dictionary:
    var weights := {}
    for raw_action: Variant in actions:
        if not raw_action is Dictionary:
            continue
        var action: Dictionary = raw_action
        var action_id := str(action.get("action_id", ""))
        if action_id.is_empty():
            continue
        if condition_filter.is_valid() and not bool(condition_filter.call(action)):
            continue
        var weight := maxf(0.0, float(action.get("weight", 0.0)))
        if tendency in TENDENCIES:
            var tendency_weights: Variant = action.get("tendency_weights", {})
            if tendency_weights is Dictionary:
                weight *= maxf(0.0, float(tendency_weights.get(tendency, 1.0)))
        if weight > 0.0:
            weights[action_id] = weight
    return weights


func choose_action(
    actions: Array,
    tendency: String,
    condition_filter: Callable,
    rng: RefCounted,
) -> Dictionary:
    var weights := build_weights(actions, tendency, condition_filter)
    var total := 0.0
    for raw_weight: Variant in weights.values():
        total += float(raw_weight)
    if total <= 0.0:
        return {}
    var roll := float(rng.call("next_float")) * total
    var running := 0.0
    # The source array is the stable tie/order authority; Dictionary order is ignored.
    for raw_action: Variant in actions:
        if not raw_action is Dictionary:
            continue
        var action: Dictionary = raw_action
        var action_id := str(action.get("action_id", ""))
        if not weights.has(action_id):
            continue
        running += float(weights[action_id])
        if roll < running:
            return action.duplicate(true)
    for index: int in range(actions.size() - 1, -1, -1):
        var fallback: Variant = actions[index]
        if fallback is Dictionary and weights.has(str(fallback.get("action_id", ""))):
            return fallback.duplicate(true)
    return {}
