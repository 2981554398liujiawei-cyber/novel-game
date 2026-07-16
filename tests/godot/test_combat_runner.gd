extends SceneTree

const GameStateClass = preload("res://src/core/game_state.gd")
const InventoryManagerClass = preload("res://src/core/inventory_manager.gd")
const CombatRunnerClass = preload("res://src/core/combat_runner.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")

const STATE_FIXTURE := "res://content/tests/fixtures/inventory_manager/state_registry.json"
const ITEM_FIXTURE := "res://content/tests/fixtures/inventory_manager/items.json"
const COMBAT_FIXTURE := "res://content/tests/fixtures/combat_runner/combats.json"
const ENEMY_FIXTURE := "res://content/tests/fixtures/combat_runner/enemies.json"
const SKILL_FIXTURE := "res://content/tests/fixtures/combat_runner/skills.json"
const STORY_STATE_FIXTURE := "res://content/tests/fixtures/game_state/state_registry.json"
const STORY_FIXTURE := "res://content/tests/fixtures/story_runner/minimal_story.json"

const BASIC := "TEST_COMBAT_BASIC"
const SOLO := "TEST_COMBAT_SOLO"
const BOSS := "TEST_COMBAT_BOSS"
const PARTIAL := "TEST_COMBAT_PARTIAL"
const PLAYER := "TEST_UNIT_PLAYER"
const COMPANION := "TEST_UNIT_COMPANION"
const DUMMY := "TEST_UNIT_DUMMY_A"
const SOLO_PLAYER := "TEST_UNIT_SOLO_PLAYER"
const BRUTE := "TEST_UNIT_BRUTE_A"
const BOSS_PLAYER := "TEST_UNIT_BOSS_PLAYER"
const BOSS_COMPANION := "TEST_UNIT_BOSS_COMPANION"
const BOSS_ENEMY := "TEST_UNIT_BOSS_A"
const PARTIAL_PLAYER := "TEST_UNIT_PARTIAL_PLAYER"
const PARTIAL_DUMMY := "TEST_UNIT_PARTIAL_DUMMY"

const POWER_STRIKE := "TEST_SKILL_POWER_STRIKE"
const POISON_EDGE := "TEST_SKILL_POISON_EDGE"
const STUN_BLOW := "TEST_SKILL_STUN_BLOW"
const RALLY := "TEST_SKILL_RALLY"
const BREAK_ARMOR := "TEST_SKILL_BREAK_ARMOR"
const PERIODIC_PULSE := "TEST_SKILL_PERIODIC_PULSE"
const GROUP_STRIKE := "TEST_SKILL_GROUP_STRIKE"
const ANY_HEAL := "TEST_SKILL_ANY_HEAL"
const GROUP_HEAL := "TEST_SKILL_GROUP_HEAL"
const STATE_MARK := "TEST_SKILL_STATE_MARK"
const REVEAL_MECHANIC := "TEST_SKILL_REVEAL_MECHANIC"
const DOUBLE_POISON := "TEST_SKILL_DOUBLE_POISON"
const PASSIVE_AURA := "TEST_SKILL_PASSIVE_AURA"
const BATTLE_TONIC := "TEST_ITEM_BATTLE_TONIC"
const FIELD_TONIC := "TEST_ITEM_FIELD_TONIC"
const TWO_HANDED_SWORD := "TEST_ITEM_TWO_HANDED_SWORD"


class FixtureContentLoader extends RefCounted:
    var state_definitions: Array
    var item_definitions: Array
    var combat_definitions: Array
    var enemy_definitions: Array
    var skill_definitions: Array
    var runtime_registry: Dictionary
    var story: Dictionary

    func _init(
        states: Array,
        items: Array,
        combats: Array,
        enemies: Array,
        skills: Array,
        registry: Dictionary,
        story_document: Dictionary,
    ) -> void:
        state_definitions = states
        item_definitions = items
        combat_definitions = combats
        enemy_definitions = enemies
        skill_definitions = skills
        runtime_registry = registry
        story = story_document

    func get_state_definitions() -> Array:
        return state_definitions.duplicate(true)

    func get_item_definitions() -> Array:
        return item_definitions.duplicate(true)

    func get_combat_definitions() -> Array:
        return combat_definitions.duplicate(true)

    func get_enemy_definitions() -> Array:
        return enemy_definitions.duplicate(true)

    func get_skill_definitions() -> Array:
        return skill_definitions.duplicate(true)

    func get_combat_runtime_registry() -> Dictionary:
        return runtime_registry.duplicate(true)

    func get_story(story_id: String) -> Variant:
        if story_id != str(story.get("quest_id", "")):
            return null
        return story.duplicate(true)


class CheckpointSaveManager extends RefCounted:
    var random_state: Dictionary = {"seed": 0}
    var runtime_guard_set := false
    var checkpoint_count := 0

    func get_random_state() -> Dictionary:
        return random_state.duplicate(true)

    func set_random_state(value: Dictionary) -> bool:
        random_state = value.duplicate(true)
        return true

    func create_precombat_checkpoint() -> Dictionary:
        checkpoint_count += 1
        return {"ok": true, "code": "OK", "slot_id": "auto"}

    func set_runtime_guard(value: RefCounted = null) -> Dictionary:
        runtime_guard_set = value != null
        return {"ok": true, "code": "OK"}


class SignalRecorder extends RefCounted:
    var counts := {
        "checkpoint": 0,
        "started": 0,
        "round": 0,
        "turn": 0,
        "action": 0,
        "damage": 0,
        "heal": 0,
        "status": 0,
        "defeated": 0,
        "phase": 0,
        "finished": 0,
        "error": 0,
    }
    var action_types: Array[String] = []
    var phases: Array[String] = []
    var last_finished: Dictionary = {}

    func bind(runner: RefCounted) -> void:
        runner.precombat_checkpoint_requested.connect(_on_checkpoint)
        runner.combat_started.connect(_on_started)
        runner.round_started.connect(_on_round)
        runner.turn_started.connect(_on_turn)
        runner.action_resolved.connect(_on_action)
        runner.unit_damaged.connect(_on_damage)
        runner.unit_healed.connect(_on_heal)
        runner.status_applied.connect(_on_status)
        runner.unit_defeated.connect(_on_defeated)
        runner.phase_changed.connect(_on_phase)
        runner.combat_finished.connect(_on_finished)
        runner.combat_error.connect(_on_error)

    func _on_checkpoint(_payload: Dictionary) -> void:
        counts["checkpoint"] += 1

    func _on_started(_payload: Dictionary) -> void:
        counts["started"] += 1

    func _on_round(_payload: Dictionary) -> void:
        counts["round"] += 1

    func _on_turn(_payload: Dictionary) -> void:
        counts["turn"] += 1

    func _on_action(payload: Dictionary) -> void:
        counts["action"] += 1
        action_types.append(str(payload.get("action_type", "")))

    func _on_damage(_payload: Dictionary) -> void:
        counts["damage"] += 1

    func _on_heal(_payload: Dictionary) -> void:
        counts["heal"] += 1

    func _on_status(_payload: Dictionary) -> void:
        counts["status"] += 1

    func _on_defeated(_payload: Dictionary) -> void:
        counts["defeated"] += 1

    func _on_phase(payload: Dictionary) -> void:
        counts["phase"] += 1
        phases.append(str(payload.get("new_phase_id", "")))

    func _on_finished(payload: Dictionary) -> void:
        counts["finished"] += 1
        last_finished = payload.duplicate(true)

    func _on_error(_payload: Dictionary) -> void:
        counts["error"] += 1


var _failures: Array[String] = []
var _scenario_count := 0
var _states: Array = []
var _items: Array = []
var _combats: Array = []
var _enemies: Array = []
var _skills: Array = []
var _registry: Dictionary = {}
var _story: Dictionary = {}


func _init() -> void:
    if not _load_fixtures():
        _finish()
        return

    _test_initialization_start_and_order()
    _test_seed_and_damage_determinism()
    _test_solo_full_combat_replay()
    _test_guard_and_turn_progression()
    _test_skill_cooldown_uses_and_targets()
    _test_schema_runtime_alignment()
    _test_inventory_item_atomicity()
    _test_equipment_modifier_and_companion_auto_action()
    _test_status_lifecycle_and_stat_effects()
    _test_inspect_cache_and_seeded_result()
    _test_enemy_ai_and_companion_tendency()
    _test_boss_and_event_phases()
    _test_victory_defeat_retreat_and_partial_success()
    _test_snapshot_persistence_policy_and_cleanup()
    _test_actual_save_manager_guard()
    _test_errors_signals_and_module_boundaries()
    _finish()


func _test_initialization_start_and_order() -> void:
    _case("normal fixture initialization and start")
    var context := _new_context("normal_start")
    if context.is_empty():
        return
    var runner: RefCounted = context["combat"]
    var start: Dictionary = runner.start_combat(BASIC, 1101)
    _expect_ok(start, "normal combat start")
    _expect(runner.is_active(), "combat did not become active")
    _expect(runner.get_round() == 1, "combat did not enter round one")
    _expect(not runner.get_current_actor().is_empty(), "combat has no current actor")

    _case("agility initiative and stable tie rule")
    var snapshot: Dictionary = runner.export_runtime_snapshot()
    var order: Array = runner.get_action_order()
    var scores: Dictionary = snapshot["runtime"]["initiative_scores"]
    _expect(order.size() == 3, "basic combat action order does not contain three units")
    for index: int in range(1, order.size()):
        var previous_id := str(order[index - 1])
        var current_id := str(order[index])
        var previous_score := float(scores[previous_id])
        var current_score := float(scores[current_id])
        _expect(previous_score >= current_score, "initiative order is not descending by score")
        if is_equal_approx(previous_score, current_score):
            var previous_role := str(snapshot["runtime"]["units"][previous_id]["role"])
            var current_role := str(snapshot["runtime"]["units"][current_id]["role"])
            _expect(
                previous_role == "player" or current_role != "player",
                "initiative tie did not prefer the player",
            )
            if previous_role == current_role:
                _expect(previous_id < current_id, "initiative tie was not stable by unit ID")

    _case("all three roles participate in one order")
    var roles := {}
    for raw_unit_id: Variant in order:
        roles[str(snapshot["runtime"]["units"][str(raw_unit_id)]["role"])] = true
    _expect(roles.has("player"), "player was omitted from action order")
    _expect(roles.has("companion"), "companion was omitted from action order")
    _expect(roles.has("enemy"), "enemy was omitted from action order")

    _case("unknown combat ID fails explicitly")
    runner.abort_combat("defeat", "test_cleanup")
    var unknown: Dictionary = runner.start_combat("TEST_COMBAT_UNKNOWN", 1)
    _expect_code(unknown, "COMBAT_NOT_FOUND", "unknown combat ID")

    _case("maximum four equipped skills")
    var boss_context := _new_context("four_skills")
    if not boss_context.is_empty():
        var boss_runner: RefCounted = boss_context["combat"]
        _expect_ok(boss_runner.start_combat(BOSS, 1102), "boss combat start for skill limit")
        _expect(boss_runner.get_unit_state(BOSS_PLAYER).get("skill_ids", []).size() == 4, "player did not retain four equipped skills")
        _expect(boss_runner.get_unit_state(BOSS_ENEMY).get("skill_ids", []).size() == 4, "boss did not retain four equipped skills")


func _test_seed_and_damage_determinism() -> void:
    _case("equal-agility initiative is seeded and reproducible")
    var tie_first := _new_context_with_equal_agility("tie_order_first")
    var tie_second := _new_context_with_equal_agility("tie_order_second")
    if not tie_first.is_empty() and not tie_second.is_empty():
        var tie_first_runner: RefCounted = tie_first["combat"]
        var tie_second_runner: RefCounted = tie_second["combat"]
        _expect_ok(tie_first_runner.start_combat(BASIC, 2199), "first equal-agility start")
        _expect_ok(tie_second_runner.start_combat(BASIC, 2199), "second equal-agility start")
        var tie_order: Array = tie_first_runner.get_action_order()
        _expect(tie_order == tie_second_runner.get_action_order(), "equal agility was not reproducible for the same seed")
        var observed_different_order := false
        for seed: int in range(2200, 2232):
            var variant_context := _new_context_with_equal_agility("tie_order_variant_%d" % seed)
            if variant_context.is_empty():
                continue
            var variant_runner: RefCounted = variant_context["combat"]
            _expect_ok(variant_runner.start_combat(BASIC, seed), "equal-agility variant start")
            if variant_runner.get_action_order() != tie_order:
                observed_different_order = true
                break
        _expect(observed_different_order, "equal agility never used the seeded random initiative component")

    _case("same seed produces the same order")
    var first := _new_context("seed_order_first")
    var second := _new_context("seed_order_second")
    if first.is_empty() or second.is_empty():
        return
    var first_runner: RefCounted = first["combat"]
    var second_runner: RefCounted = second["combat"]
    _expect_ok(first_runner.start_combat(BASIC, 2201), "first seeded start")
    _expect_ok(second_runner.start_combat(BASIC, 2201), "second seeded start")
    _expect(first_runner.get_action_order() == second_runner.get_action_order(), "same seed produced different action order")
    _expect(
        first_runner.export_runtime_snapshot()["rng"] == second_runner.export_runtime_snapshot()["rng"],
        "same seed produced different random state after initiative",
    )

    _case("same seed produces the same damage")
    _force_turn(first_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
    _force_turn(second_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
    var first_attack: Dictionary = first_runner.perform_action({"type": "attack", "target_id": DUMMY})
    var second_attack: Dictionary = second_runner.perform_action({"type": "attack", "target_id": DUMMY})
    _expect_ok(first_attack, "first deterministic attack")
    _expect_ok(second_attack, "second deterministic attack")
    _expect(first_attack.get("damage") == second_attack.get("damage"), "same seed produced different attack damage")
    _expect(first_attack.get("critical") == second_attack.get("critical"), "same seed produced different critical result")

    _case("damage stays inside data-driven variance bounds")
    var damage := int(first_attack.get("damage", 0))
    _expect(damage >= 17 and damage <= 24, "basic damage fell outside the configured formula bounds: %d" % damage)
    _expect(float(first_runner.get_unit_state(DUMMY).get("hp", 32.0)) == 32.0 - float(damage), "damage did not update target HP exactly")

    _case("minimum damage prevents zero or negative hits")
    var minimum_context := _new_context("minimum_damage")
    if not minimum_context.is_empty():
        var minimum_runner: RefCounted = minimum_context["combat"]
        _expect_ok(minimum_runner.start_combat(BASIC, 2209), "minimum-damage combat start")
        var minimum_setup: Dictionary = minimum_runner.export_runtime_snapshot()
        minimum_setup["runtime"]["units"][PLAYER]["attack"] = 0.0
        minimum_setup["runtime"]["units"][DUMMY]["defense"] = 999.0
        minimum_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        minimum_setup["runtime"]["turn_index"] = 0
        _expect(minimum_runner.restore_runtime_snapshot(minimum_setup), "minimum-damage setup")
        var minimum_hit: Dictionary = minimum_runner.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(int(minimum_hit.get("damage", 0)) == 1, "configured minimum damage did not produce exactly one damage")

    _case("registered critical chance and multiplier are applied")
    var critical_context := _new_context("critical_damage")
    if not critical_context.is_empty():
        var critical_runner: RefCounted = critical_context["combat"]
        _expect_ok(critical_runner.start_combat(BASIC, 2210), "critical combat start")
        var critical_setup: Dictionary = critical_runner.export_runtime_snapshot()
        critical_setup["runtime"]["units"][DUMMY]["max_hp"] = 100.0
        critical_setup["runtime"]["units"][DUMMY]["hp"] = 100.0
        critical_setup["runtime"]["units"][PLAYER]["critical_chance"] = 1.0
        critical_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        critical_setup["runtime"]["turn_index"] = 0
        var normal_setup: Dictionary = critical_setup.duplicate(true)
        normal_setup["runtime"]["units"][PLAYER]["critical_chance"] = 0.0
        _expect(critical_runner.restore_runtime_snapshot(normal_setup), "normal-hit comparison setup")
        var normal_hit: Dictionary = critical_runner.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(critical_runner.restore_runtime_snapshot(critical_setup), "critical-hit comparison setup")
        var critical_hit: Dictionary = critical_runner.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(bool(critical_hit.get("critical", false)), "one-hundred-percent critical chance did not critical")
        _expect(int(critical_hit.get("damage", 0)) > int(normal_hit.get("damage", 0)), "critical multiplier did not increase damage")

    _case("different seeds can produce different deterministic streams")
    var signatures := {}
    for seed: int in [2202, 2203, 2204, 2205, 2206, 2207]:
        var context := _new_context("different_seed_%d" % seed)
        if context.is_empty():
            continue
        var runner: RefCounted = context["combat"]
        if not bool(runner.start_combat(BASIC, seed).get("ok", false)):
            continue
        _force_turn(runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        var result: Dictionary = runner.perform_action({"type": "attack", "target_id": DUMMY})
        signatures["%s:%s" % [str(runner.get_action_order()), str(result.get("damage", -1))]] = true
    _expect(signatures.size() >= 2, "different seeds never changed order or damage across the fixture sample")

    _case("snapshot restores the random stream exactly")
    var replay_context := _new_context("rng_replay")
    if not replay_context.is_empty():
        var replay: RefCounted = replay_context["combat"]
        _expect_ok(replay.start_combat(BASIC, 2208), "RNG replay start")
        var setup: Dictionary = replay.export_runtime_snapshot()
        setup["runtime"]["units"][DUMMY]["max_hp"] = 100.0
        setup["runtime"]["units"][DUMMY]["hp"] = 100.0
        setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        setup["runtime"]["turn_index"] = 0
        _expect(replay.restore_runtime_snapshot(setup), "RNG replay setup restore")
        var before: Dictionary = replay.export_runtime_snapshot()
        var one: Dictionary = replay.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(replay.restore_runtime_snapshot(before), "RNG replay restore")
        var two: Dictionary = replay.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(one.get("damage") == two.get("damage") and one.get("variance") == two.get("variance"), "restored RNG did not replay the same action")


func _test_solo_full_combat_replay() -> void:
    _case("one-versus-one combat runs normally without a companion")
    var first := _new_context("solo_full_first")
    var second := _new_context("solo_full_second")
    if first.is_empty() or second.is_empty():
        return
    var first_runner: RefCounted = first["combat"]
    var second_runner: RefCounted = second["combat"]
    _expect_ok(first_runner.start_combat(SOLO, 2251), "first full solo start")
    _expect_ok(second_runner.start_combat(SOLO, 2251), "second full solo start")
    for runner: RefCounted in [first_runner, second_runner]:
        var setup: Dictionary = runner.export_runtime_snapshot()
        setup["runtime"]["units"][SOLO_PLAYER]["max_hp"] = 300.0
        setup["runtime"]["units"][SOLO_PLAYER]["hp"] = 300.0
        setup["runtime"]["units"][SOLO_PLAYER]["attack"] = 30.0
        _expect(runner.restore_runtime_snapshot(setup), "full solo durable-player setup")
    var roles: Array = []
    for raw_unit: Variant in first_runner.export_runtime_snapshot()["runtime"]["units"].values():
        roles.append(str(raw_unit.get("role", "")))
    _expect("player" in roles and "enemy" in roles and "companion" not in roles, "solo fixture did not remain one-versus-one")
    var first_result := _run_full_solo(first_runner)
    _expect(first_result.get("result_type") == "victory", "normal one-versus-one loop did not reach victory")

    _case("same seed and command policy produce an identical full result")
    var second_result := _run_full_solo(second_runner)
    _expect(second_result == first_result, "same seed and command sequence produced a different full combat result")


func _test_guard_and_turn_progression() -> void:
    _case("defend applies registered guard")
    var context := _new_context_with_enemy_ai("guard", "TEST_ENEMY_DUMMY", [{
        "action_id": "guard_test_attack",
        "mode": "weighted_action",
        "action_type": "attack",
        "weight": 1.0,
        "conditions": [],
        "target_priority": "player",
    }], {"attack": 30})
    if context.is_empty():
        return
    var runner: RefCounted = context["combat"]
    _expect_ok(runner.start_combat(BASIC, 3301), "guard combat start")
    _force_turn(runner, PLAYER, [PLAYER, DUMMY, COMPANION])
    _expect_ok(runner.perform_action({"type": "defend"}), "defend action")
    var guarded: Dictionary = runner.export_runtime_snapshot()
    _expect(guarded["runtime"]["units"][PLAYER]["statuses"].has("guard"), "defend did not apply guard")

    _case("guard reduces direct damage by forty percent")
    var no_guard: Dictionary = guarded.duplicate(true)
    no_guard["runtime"]["units"][PLAYER]["statuses"].erase("guard")
    _expect(runner.restore_runtime_snapshot(no_guard), "unguarded comparison restore")
    var unguarded_hit: Dictionary = runner.run_auto_turn()
    _expect_ok(unguarded_hit, "unguarded comparison hit")
    _expect(runner.restore_runtime_snapshot(guarded), "guarded comparison restore")
    var guarded_hit: Dictionary = runner.run_auto_turn()
    _expect_ok(guarded_hit, "guarded comparison hit")
    _expect(int(guarded_hit.get("damage", 0)) <= int(floor(float(unguarded_hit.get("damage", 0)) * 0.65)), "guard did not reduce direct damage by approximately forty percent")

    _case("guard expires at the owner's next action start")
    var expiry_setup: Dictionary = guarded.duplicate(true)
    expiry_setup["runtime"]["turn_order"] = [DUMMY, PLAYER, COMPANION]
    expiry_setup["runtime"]["turn_index"] = 0
    _expect(runner.restore_runtime_snapshot(expiry_setup), "guard expiry setup")
    _expect_ok(runner.run_auto_turn(), "hit before guard expiry")
    _expect(str(runner.get_current_actor().get("unit_id", "")) == PLAYER, "turn did not advance to the player")
    _expect(not runner.get_unit_state(PLAYER).get("statuses", {}).has("guard"), "guard remained after the player's next action start")

    _case("player action advances to the next legal actor")
    var turn_context := _new_context("turn_progression")
    if not turn_context.is_empty():
        var turn_runner: RefCounted = turn_context["combat"]
        _expect_ok(turn_runner.start_combat(BASIC, 3302), "turn progression start")
        _force_turn(turn_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        _expect_ok(turn_runner.perform_action({"type": "defend"}), "turn progression defend")
        _expect(str(turn_runner.get_current_actor().get("unit_id", "")) == COMPANION, "turn did not advance to the configured next actor")


func _test_skill_cooldown_uses_and_targets() -> void:
    _case("skill applies damage and records cooldown and uses")
    var context := _new_context("skill_cooldown")
    if context.is_empty():
        return
    var runner: RefCounted = context["combat"]
    _expect_ok(runner.start_combat(SOLO, 4401), "skill combat start")
    _force_turn(runner, SOLO_PLAYER, [SOLO_PLAYER, BRUTE])
    var strike: Dictionary = runner.perform_action({"type": "skill", "skill_id": POWER_STRIKE, "target_id": BRUTE})
    _expect_ok(strike, "power strike")
    var player_state: Dictionary = runner.get_unit_state(SOLO_PLAYER)
    _expect(int(player_state.get("skill_uses", {}).get(POWER_STRIKE, 0)) == 1, "skill use count was not recorded")
    _expect(int(player_state.get("cooldowns", {}).get(POWER_STRIKE, 0)) == 2, "skill cooldown did not include exactly one future owner turn")

    _case("cooldown rejects early reuse atomically")
    _force_turn(runner, SOLO_PLAYER, [SOLO_PLAYER, BRUTE])
    var before_cooldown: Dictionary = runner.export_runtime_snapshot()
    var blocked: Dictionary = runner.perform_action({"type": "skill", "skill_id": POWER_STRIKE, "target_id": BRUTE})
    _expect_code(blocked, "SKILL_COOLDOWN", "cooldown reuse")
    _expect(runner.export_runtime_snapshot() == before_cooldown, "failed cooldown use changed combat runtime")

    _case("cooldown becomes available after the configured owner turns")
    var cooldown_setup: Dictionary = before_cooldown.duplicate(true)
    cooldown_setup["runtime"]["units"][SOLO_PLAYER]["cooldowns"][POWER_STRIKE] = 0
    _expect(runner.restore_runtime_snapshot(cooldown_setup), "cooldown expiry simulation restore")
    _force_turn(runner, SOLO_PLAYER, [SOLO_PLAYER, BRUTE])
    _expect_ok(runner.perform_action({"type": "skill", "skill_id": POWER_STRIKE, "target_id": BRUTE}), "skill after cooldown")

    _case("per-battle use limit rejects another use")
    var use_context := _new_context("skill_uses")
    if not use_context.is_empty():
        var use_runner: RefCounted = use_context["combat"]
        _expect_ok(use_runner.start_combat(SOLO, 4402), "use-limit combat start")
        _force_turn(use_runner, SOLO_PLAYER, [SOLO_PLAYER, BRUTE])
        _expect_ok(use_runner.perform_action({"type": "skill", "skill_id": STUN_BLOW, "target_id": BRUTE}), "only stun use")
        var used: Dictionary = use_runner.export_runtime_snapshot()
        if bool(used.get("active", false)):
            used["runtime"]["units"][SOLO_PLAYER]["cooldowns"].erase(STUN_BLOW)
            used["runtime"]["units"][BRUTE]["statuses"].erase("stun")
            used["runtime"]["turn_order"] = [SOLO_PLAYER, BRUTE]
            used["runtime"]["turn_index"] = 0
            _expect(use_runner.restore_runtime_snapshot(used), "use-limit setup restore")
            _expect_code(
                use_runner.perform_action({"type": "skill", "skill_id": STUN_BLOW, "target_id": BRUTE}),
                "SKILL_USES_EXHAUSTED",
                "stun use limit",
            )

    _case("unknown and unequipped skill IDs fail explicitly")
    var error_context := _new_context("skill_errors")
    if not error_context.is_empty():
        var error_runner: RefCounted = error_context["combat"]
        _expect_ok(error_runner.start_combat(SOLO, 4403), "skill error start")
        _force_turn(error_runner, SOLO_PLAYER, [SOLO_PLAYER, BRUTE])
        _expect_code(error_runner.perform_action({"type": "skill", "skill_id": "TEST_SKILL_UNKNOWN", "target_id": BRUTE}), "SKILL_NOT_FOUND", "unknown skill")
        _expect_code(error_runner.perform_action({"type": "skill", "skill_id": RALLY, "target_id": SOLO_PLAYER}), "SKILL_UNAVAILABLE", "unequipped skill")

    _case("skill target type is enforced")
    var target_context := _new_context("skill_target")
    if not target_context.is_empty():
        var target_runner: RefCounted = target_context["combat"]
        _expect_ok(target_runner.start_combat(SOLO, 4404), "skill target start")
        _force_turn(target_runner, SOLO_PLAYER, [SOLO_PLAYER, BRUTE])
        _expect_code(target_runner.perform_action({"type": "skill", "skill_id": POWER_STRIKE, "target_id": SOLO_PLAYER}), "COMBAT_TARGET_INVALID", "enemy skill target contract")


func _test_schema_runtime_alignment() -> void:
    _case("periodic skill damage bypasses direct-damage guard reduction")
    var periodic_context := _new_context_with_player_skills("periodic_damage", BASIC, [PERIODIC_PULSE])
    if not periodic_context.is_empty():
        var periodic_runner: RefCounted = periodic_context["combat"]
        _expect_ok(periodic_runner.start_combat(BASIC, 5451), "periodic damage combat start")
        var guarded_setup: Dictionary = periodic_runner.export_runtime_snapshot()
        guarded_setup["runtime"]["units"][DUMMY]["max_hp"] = 100.0
        guarded_setup["runtime"]["units"][DUMMY]["hp"] = 100.0
        guarded_setup["runtime"]["units"][DUMMY]["statuses"]["guard"] = {
            "status_id": "guard", "duration": 1, "stacks": 1, "magnitude": 1.0,
            "source_id": DUMMY, "applied_round": 1,
        }
        guarded_setup["runtime"]["turn_order"] = [PLAYER, DUMMY, COMPANION]
        guarded_setup["runtime"]["turn_index"] = 0
        var unguarded_setup := guarded_setup.duplicate(true)
        unguarded_setup["runtime"]["units"][DUMMY]["statuses"].erase("guard")
        _expect(periodic_runner.restore_runtime_snapshot(unguarded_setup), "unguarded periodic setup")
        var unguarded: Dictionary = periodic_runner.perform_action({"type": "skill", "skill_id": PERIODIC_PULSE, "target_id": DUMMY})
        _expect(periodic_runner.restore_runtime_snapshot(guarded_setup), "guarded periodic setup")
        var guarded: Dictionary = periodic_runner.perform_action({"type": "skill", "skill_id": PERIODIC_PULSE, "target_id": DUMMY})
        _expect_ok(guarded, "guarded periodic skill")
        _expect(guarded.get("effects", [])[0].get("damage_type") == "periodic", "periodic damage type was not preserved")
        _expect(guarded.get("effects", [])[0].get("value") == unguarded.get("effects", [])[0].get("value"), "guard incorrectly reduced periodic skill damage")

    _case("schema target aliases enemy_all ally_all and any_single execute")
    var targets_context := _new_context_with_player_skills(
        "schema_targets",
        BASIC,
        [GROUP_STRIKE, GROUP_HEAL, ANY_HEAL],
    )
    if not targets_context.is_empty():
        var targets_runner: RefCounted = targets_context["combat"]
        _expect_ok(targets_runner.start_combat(BASIC, 5452), "schema target combat start")
        var target_setup: Dictionary = targets_runner.export_runtime_snapshot()
        target_setup["runtime"]["units"][PLAYER]["hp"] = 50.0
        target_setup["runtime"]["units"][COMPANION]["hp"] = 40.0
        target_setup["runtime"]["units"][DUMMY]["hp"] = 16.0
        target_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        target_setup["runtime"]["turn_index"] = 0
        _expect(targets_runner.restore_runtime_snapshot(target_setup), "schema target setup")
        var ally_all: Dictionary = targets_runner.perform_action({"type": "skill", "skill_id": GROUP_HEAL})
        _expect_ok(ally_all, "ally_all skill")
        _expect(PLAYER in ally_all.get("targets", []) and COMPANION in ally_all.get("targets", []), "ally_all did not resolve both allies")
        _force_turn(targets_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        var any_target: Dictionary = targets_runner.perform_action({"type": "skill", "skill_id": ANY_HEAL, "target_id": DUMMY})
        _expect_ok(any_target, "any_single skill targeting an opponent")
        _force_turn(targets_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        var enemy_all: Dictionary = targets_runner.perform_action({"type": "skill", "skill_id": GROUP_STRIKE})
        _expect_ok(enemy_all, "enemy_all skill")
        _expect(DUMMY in enemy_all.get("targets", []), "enemy_all omitted the living opponent")

    _case("schema state_effect writes through GameState")
    var effects_context := _new_context_with_player_skills(
        "schema_effects",
        BASIC,
        [STATE_MARK, REVEAL_MECHANIC, DOUBLE_POISON, PASSIVE_AURA],
    )
    if not effects_context.is_empty():
        var effects_runner: RefCounted = effects_context["combat"]
        var effects_state: RefCounted = effects_context["game_state"]
        _expect_ok(effects_runner.start_combat(BASIC, 5453), "schema effect combat start")
        _force_turn(effects_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        _expect_ok(effects_runner.perform_action({"type": "skill", "skill_id": STATE_MARK}), "direct state_effect skill")
        _expect(int(effects_state.get_state("test.combat.counter")) == 1, "state_effect did not use the formal GameState interface")

        _case("reveal_mechanic is a supported typed skill effect")
        _force_turn(effects_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        var revealed: Dictionary = effects_runner.perform_action({"type": "skill", "skill_id": REVEAL_MECHANIC, "target_id": DUMMY})
        _expect_ok(revealed, "reveal_mechanic skill")
        _expect(revealed.get("effects", [])[0].get("effect") == "reveal_mechanic", "reveal_mechanic result lost its type")

        _case("apply_status honors the schema stacks field")
        _force_turn(effects_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        _expect_ok(effects_runner.perform_action({"type": "skill", "skill_id": DOUBLE_POISON, "target_id": DUMMY}), "double poison skill")
        _expect(int(effects_runner.get_unit_state(DUMMY).get("statuses", {}).get("poison", {}).get("stacks", 0)) == 2, "apply_status ignored its stacks value")

        _case("passive skills cannot be invoked as active actions")
        _force_turn(effects_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        var before_passive: Dictionary = effects_runner.export_runtime_snapshot()
        _expect_code(effects_runner.perform_action({"type": "skill", "skill_id": PASSIVE_AURA}), "SKILL_UNAVAILABLE", "passive skill action")
        _expect(effects_runner.export_runtime_snapshot() == before_passive, "rejected passive skill changed combat state")

    _case("skill phase condition reads phase_id from schema")
    var phase_condition_context := _new_context_with_player_skills(
        "skill_phase_condition",
        BOSS,
        [STATE_MARK],
        {STATE_MARK: {"runtime": {"conditions": [{"type": "phase", "phase_id": "opening"}], "ai_tags": ["support"]}}},
    )
    if not phase_condition_context.is_empty():
        var phase_condition_runner: RefCounted = phase_condition_context["combat"]
        _expect_ok(phase_condition_runner.start_combat(BOSS, 5454), "skill phase condition start")
        _force_turn(phase_condition_runner, BOSS_PLAYER, [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY])
        _expect_ok(phase_condition_runner.perform_action({"type": "skill", "skill_id": STATE_MARK}), "opening-phase conditioned skill")

    _case("skill actor-status condition checks the actor rather than target")
    var actor_condition_context := _new_context_with_player_skills(
        "skill_actor_condition",
        BASIC,
        [DOUBLE_POISON],
        {DOUBLE_POISON: {"runtime": {"conditions": [{"type": "status", "subject": "actor", "status_id": "poison", "present": true}], "ai_tags": ["status"]}}},
    )
    if not actor_condition_context.is_empty():
        var actor_condition_runner: RefCounted = actor_condition_context["combat"]
        _expect_ok(actor_condition_runner.start_combat(BASIC, 5455), "actor condition combat start")
        var actor_condition_setup: Dictionary = actor_condition_runner.export_runtime_snapshot()
        actor_condition_setup["runtime"]["units"][PLAYER]["statuses"]["poison"] = {
            "status_id": "poison", "duration": 2, "stacks": 1, "magnitude": 1.0,
            "source_id": DUMMY, "applied_round": 1,
        }
        actor_condition_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        actor_condition_setup["runtime"]["turn_index"] = 0
        _expect(actor_condition_runner.restore_runtime_snapshot(actor_condition_setup), "actor condition setup")
        _expect_ok(actor_condition_runner.perform_action({"type": "skill", "skill_id": DOUBLE_POISON, "target_id": DUMMY}), "actor-status conditioned skill")

    _case("inspect status condition honors target_unit_id")
    var inspect_condition_context := _new_context_with_combat_runtime_mutation(
        "inspect_target_condition",
        BASIC,
        func(runtime: Dictionary) -> void:
            runtime["inspect_rules"].push_front({
                "inspect_id": "poison_status_reveal",
                "target_unit_id": DUMMY,
                "conditions": [{"type": "status", "target_unit_id": DUMMY, "status_id": "poison", "present": true}],
                "outcome": "success",
                "reveal": "synthetic_poison_status",
                "seeded": false,
                "difficulty": 0,
            })
    )
    if not inspect_condition_context.is_empty():
        var inspect_condition_runner: RefCounted = inspect_condition_context["combat"]
        _expect_ok(inspect_condition_runner.start_combat(BASIC, 5456), "inspect target condition start")
        var inspect_condition_setup: Dictionary = inspect_condition_runner.export_runtime_snapshot()
        inspect_condition_setup["runtime"]["units"][DUMMY]["statuses"]["poison"] = {
            "status_id": "poison", "duration": 2, "stacks": 1, "magnitude": 1.0,
            "source_id": PLAYER, "applied_round": 1,
        }
        inspect_condition_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        inspect_condition_setup["runtime"]["turn_index"] = 0
        _expect(inspect_condition_runner.restore_runtime_snapshot(inspect_condition_setup), "inspect target condition setup")
        var inspect_condition: Dictionary = inspect_condition_runner.perform_action({"type": "inspect", "target_id": DUMMY})
        _expect(inspect_condition.get("reveal") == "synthetic_poison_status", "inspect ignored its target_unit_id status condition")

    _case("companion_alive condition honors expected false")
    var companion_condition_context := _new_context("companion_absent_condition")
    if not companion_condition_context.is_empty():
        var companion_condition_runner: RefCounted = companion_condition_context["combat"]
        _expect_ok(companion_condition_runner.start_combat(SOLO, 5457), "companion-absent condition start")
        var companion_condition_setup: Dictionary = companion_condition_runner.export_runtime_snapshot()
        companion_condition_setup["runtime"]["units"][BRUTE]["ai_actions"] = [{
            "action_id": "guard_without_companion",
            "mode": "conditional_action",
            "action_type": "defend",
            "weight": 1.0,
            "conditions": [{"type": "companion_alive", "expected": false}],
            "target_priority": "self",
        }]
        companion_condition_setup["runtime"]["turn_order"] = [BRUTE, SOLO_PLAYER]
        companion_condition_setup["runtime"]["turn_index"] = 0
        _expect(companion_condition_runner.restore_runtime_snapshot(companion_condition_setup), "companion-absent condition setup")
        var companion_condition: Dictionary = companion_condition_runner.run_auto_turn()
        _expect(companion_condition.get("action_type") == "defend", "companion_alive ignored expected false")


func _test_inventory_item_atomicity() -> void:
    _case("battle item heals and consumes exactly one item")
    var context := _new_context("battle_item")
    if context.is_empty():
        return
    var runner: RefCounted = context["combat"]
    var inventory: RefCounted = context["inventory"]
    var game_state: RefCounted = context["game_state"]
    _expect_ok(inventory.add_item(BATTLE_TONIC, 2), "battle tonic setup")
    _expect_ok(runner.start_combat(BASIC, 5501), "battle item combat start")
    var setup: Dictionary = runner.export_runtime_snapshot()
    setup["runtime"]["units"][PLAYER]["hp"] = 50.0
    setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
    setup["runtime"]["turn_index"] = 0
    _expect(runner.restore_runtime_snapshot(setup), "battle item HP setup")
    var used: Dictionary = runner.perform_action({"type": "item", "item_id": BATTLE_TONIC, "target_id": PLAYER})
    _expect_ok(used, "battle tonic use")
    _expect(float(runner.get_unit_state(PLAYER).get("hp", 0.0)) == 65.0, "battle tonic did not heal exactly fifteen HP")
    _expect(_item_quantity(inventory, BATTLE_TONIC) == 1, "battle tonic did not consume exactly one item")
    _expect(bool(game_state.get_state("test.inventory.battle_buff")), "battle item did not route its state effect through GameState")

    _case("missing item fails without changing runtime or inventory")
    var missing_context := _new_context("missing_battle_item")
    if not missing_context.is_empty():
        var missing_runner: RefCounted = missing_context["combat"]
        var missing_inventory: RefCounted = missing_context["inventory"]
        _expect_ok(missing_runner.start_combat(BASIC, 5502), "missing item combat start")
        _force_turn(missing_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        var runtime_before: Dictionary = missing_runner.export_runtime_snapshot()
        var inventory_before: Dictionary = missing_inventory.export_snapshot()
        _expect_code(missing_runner.perform_action({"type": "item", "item_id": BATTLE_TONIC, "target_id": PLAYER}), "ITEM_USE_FAILED", "missing battle item")
        _expect(missing_runner.export_runtime_snapshot() == runtime_before, "failed item use changed combat runtime")
        _expect(missing_inventory.export_snapshot() == inventory_before, "failed item use changed inventory")

    _case("invalid item target does not consume the item")
    var target_context := _new_context("item_target")
    if not target_context.is_empty():
        var target_runner: RefCounted = target_context["combat"]
        var target_inventory: RefCounted = target_context["inventory"]
        _expect_ok(target_inventory.add_item(BATTLE_TONIC, 1), "invalid target item setup")
        _expect_ok(target_runner.start_combat(BASIC, 5503), "invalid target combat start")
        _force_turn(target_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        _expect_code(target_runner.perform_action({"type": "item", "item_id": BATTLE_TONIC, "target_id": DUMMY}), "COMBAT_TARGET_INVALID", "enemy item target")
        _expect(_item_quantity(target_inventory, BATTLE_TONIC) == 1, "invalid target consumed the item")

    _case("field-only item is rejected in combat without consumption")
    var field_context := _new_context("field_item_in_combat")
    if not field_context.is_empty():
        var field_runner: RefCounted = field_context["combat"]
        var field_inventory: RefCounted = field_context["inventory"]
        _expect_ok(field_inventory.add_item(FIELD_TONIC, 1), "field-only item setup")
        _expect_ok(field_runner.start_combat(BASIC, 5504), "field-only item combat start")
        _force_turn(field_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        _expect_code(field_runner.perform_action({"type": "item", "item_id": FIELD_TONIC, "target_id": PLAYER}), "ITEM_USE_FAILED", "field-only item in combat")
        _expect(_item_quantity(field_inventory, FIELD_TONIC) == 1, "field-only item was consumed by failed combat use")


func _test_equipment_modifier_and_companion_auto_action() -> void:
    _case("equipped stat modifiers enter the player combat unit")
    var equipment_context := _new_context("combat_equipment")
    if not equipment_context.is_empty():
        var equipment_inventory: RefCounted = equipment_context["inventory"]
        var equipment_runner: RefCounted = equipment_context["combat"]
        _expect_ok(equipment_inventory.add_item(TWO_HANDED_SWORD, 1), "combat equipment setup")
        _expect_ok(equipment_inventory.equip_item(TWO_HANDED_SWORD, "weapon"), "combat equipment equip")
        _expect_ok(equipment_runner.start_combat(BASIC, 5601), "equipped combat start")
        var equipped_player: Dictionary = equipment_runner.get_unit_state(PLAYER)
        _expect(float(equipped_player.get("attack", 0.0)) == 24.0, "equipped attack modifier did not enter combat stats")
        _expect(float(equipped_player.get("equipment_modifiers", {}).get("attack", 0.0)) == 2.0, "combat unit did not expose the composed equipment modifier")

    _case("companion takes its turn through the shared AI interface")
    var companion_context := _new_context("companion_auto_action")
    if not companion_context.is_empty():
        var companion_runner: RefCounted = companion_context["combat"]
        _expect_ok(companion_runner.start_combat(BASIC, 5602), "companion auto-action start")
        _force_turn(companion_runner, COMPANION, [COMPANION, PLAYER, DUMMY])
        var companion_action: Dictionary = companion_runner.run_auto_turn()
        _expect_ok(companion_action, "companion automatic action")
        _expect(companion_action.get("actor_id") == COMPANION, "automatic companion action used the wrong actor")
        _expect(companion_action.get("target_id", DUMMY) == DUMMY, "automatic companion action selected an illegal target")


func _test_status_lifecycle_and_stat_effects() -> void:
    _case("poison stacks to its registered cap")
    var poison_context := _new_context("poison")
    if poison_context.is_empty():
        return
    var poison_runner: RefCounted = poison_context["combat"]
    _expect_ok(poison_runner.start_combat(BASIC, 6601), "poison combat start")
    var poison_setup: Dictionary = poison_runner.export_runtime_snapshot()
    poison_setup["runtime"]["units"][DUMMY]["max_hp"] = 100.0
    poison_setup["runtime"]["units"][DUMMY]["hp"] = 100.0
    poison_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
    poison_setup["runtime"]["turn_index"] = 0
    _expect(poison_runner.restore_runtime_snapshot(poison_setup), "poison setup restore")
    _expect_ok(poison_runner.perform_action({"type": "skill", "skill_id": POISON_EDGE, "target_id": DUMMY}), "first poison application")
    var second_poison: Dictionary = poison_runner.export_runtime_snapshot()
    second_poison["runtime"]["units"][PLAYER]["cooldowns"].erase(POISON_EDGE)
    second_poison["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
    second_poison["runtime"]["turn_index"] = 0
    _expect(poison_runner.restore_runtime_snapshot(second_poison), "second poison setup")
    _expect_ok(poison_runner.perform_action({"type": "skill", "skill_id": POISON_EDGE, "target_id": DUMMY}), "second poison application")
    var poisoned: Dictionary = poison_runner.get_unit_state(DUMMY)
    _expect(int(poisoned.get("statuses", {}).get("poison", {}).get("stacks", 0)) == 2, "poison did not stack to two")

    _case("poison ticks and duration decreases at round end")
    var tick_setup: Dictionary = poison_runner.export_runtime_snapshot()
    var hp_before_tick := float(tick_setup["runtime"]["units"][DUMMY]["hp"])
    tick_setup["runtime"]["turn_order"] = [PLAYER]
    tick_setup["runtime"]["turn_index"] = 0
    _expect(poison_runner.restore_runtime_snapshot(tick_setup), "poison tick setup")
    _expect_ok(poison_runner.perform_action({"type": "defend"}), "action ending poison round")
    var after_tick: Dictionary = poison_runner.get_unit_state(DUMMY)
    _expect(float(after_tick.get("hp", hp_before_tick)) <= hp_before_tick - 10.0, "two poison stacks did not deal max-HP periodic damage")
    _expect(int(after_tick.get("statuses", {}).get("poison", {}).get("duration", 0)) == 1, "poison duration did not decrease at round end")

    _case("stun skips exactly one action and is consumed")
    var stun_context := _new_context("stun")
    if not stun_context.is_empty():
        var stun_runner: RefCounted = stun_context["combat"]
        var recorder := SignalRecorder.new()
        recorder.bind(stun_runner)
        _expect_ok(stun_runner.start_combat(SOLO, 6602), "stun combat start")
        _force_turn(stun_runner, SOLO_PLAYER, [SOLO_PLAYER, BRUTE])
        _expect_ok(stun_runner.perform_action({"type": "skill", "skill_id": STUN_BLOW, "target_id": BRUTE}), "stun application")
        _expect("status_skip" in recorder.action_types, "stunned enemy did not emit a skipped action")
        if stun_runner.is_active():
            _expect(not stun_runner.get_unit_state(BRUTE).get("statuses", {}).has("stun"), "stun remained after blocking one action")

    _case("registered action_start status timing ticks only the acting unit")
    var action_status_context := _new_context_with_status_override(
        "action_start_status",
        "poison",
        {"duration_tick": "action_start"},
    )
    if not action_status_context.is_empty():
        var action_status_runner: RefCounted = action_status_context["combat"]
        _expect_ok(action_status_runner.start_combat(BASIC, 6606), "action-start status combat start")
        var action_status_setup: Dictionary = action_status_runner.export_runtime_snapshot()
        action_status_setup["runtime"]["units"][COMPANION]["statuses"]["poison"] = {
            "status_id": "poison", "duration": 2, "stacks": 1, "magnitude": 1.0,
            "source_id": PLAYER, "applied_round": 1,
        }
        action_status_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        action_status_setup["runtime"]["turn_index"] = 0
        var companion_hp := float(action_status_setup["runtime"]["units"][COMPANION]["hp"])
        _expect(action_status_runner.restore_runtime_snapshot(action_status_setup), "action-start status setup")
        _expect_ok(action_status_runner.perform_action({"type": "defend"}), "action advancing into status tick")
        var action_status_unit: Dictionary = action_status_runner.get_unit_state(COMPANION)
        _expect(float(action_status_unit.get("hp", companion_hp)) < companion_hp, "action_start status did not tick on owner turn")
        _expect(int(action_status_unit.get("statuses", {}).get("poison", {}).get("duration", 0)) == 1, "action_start duration did not decrease")

    _case("attack_up increases direct damage")
    var buff_context := _new_context_with_player_skills("attack_up", BASIC, [RALLY])
    if not buff_context.is_empty():
        var buff_runner: RefCounted = buff_context["combat"]
        _expect_ok(buff_runner.start_combat(BASIC, 6603), "attack-up combat start")
        var buff_setup: Dictionary = buff_runner.export_runtime_snapshot()
        buff_setup["runtime"]["units"][DUMMY]["max_hp"] = 100.0
        buff_setup["runtime"]["units"][DUMMY]["hp"] = 100.0
        buff_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        buff_setup["runtime"]["turn_index"] = 0
        _expect(buff_runner.restore_runtime_snapshot(buff_setup), "attack-up setup")
        _expect_ok(buff_runner.perform_action({"type": "skill", "skill_id": RALLY, "target_id": PLAYER}), "rally skill")
        var with_buff: Dictionary = buff_runner.export_runtime_snapshot()
        with_buff["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        with_buff["runtime"]["turn_index"] = 0
        var without_buff: Dictionary = with_buff.duplicate(true)
        without_buff["runtime"]["units"][PLAYER]["statuses"].erase("attack_up")
        _expect(buff_runner.restore_runtime_snapshot(without_buff), "unbuffed damage restore")
        var plain: Dictionary = buff_runner.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(buff_runner.restore_runtime_snapshot(with_buff), "buffed damage restore")
        var boosted: Dictionary = buff_runner.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(int(boosted.get("damage", 0)) > int(plain.get("damage", 0)), "attack_up did not increase damage")

    _case("defense_down increases damage against the target")
    var debuff_context := _new_context_with_player_skills("defense_down", BASIC, [BREAK_ARMOR])
    if not debuff_context.is_empty():
        var debuff_runner: RefCounted = debuff_context["combat"]
        _expect_ok(debuff_runner.start_combat(BASIC, 6604), "defense-down combat start")
        var debuff_setup: Dictionary = debuff_runner.export_runtime_snapshot()
        debuff_setup["runtime"]["units"][DUMMY]["max_hp"] = 100.0
        debuff_setup["runtime"]["units"][DUMMY]["hp"] = 100.0
        debuff_setup["runtime"]["units"][DUMMY]["defense"] = 30.0
        debuff_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        debuff_setup["runtime"]["turn_index"] = 0
        _expect(debuff_runner.restore_runtime_snapshot(debuff_setup), "defense-down setup")
        _expect_ok(debuff_runner.perform_action({"type": "skill", "skill_id": BREAK_ARMOR, "target_id": DUMMY}), "armor break skill")
        var with_debuff: Dictionary = debuff_runner.export_runtime_snapshot()
        with_debuff["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
        with_debuff["runtime"]["turn_index"] = 0
        var without_debuff: Dictionary = with_debuff.duplicate(true)
        without_debuff["runtime"]["units"][DUMMY]["statuses"].erase("defense_down")
        _expect(debuff_runner.restore_runtime_snapshot(without_debuff), "normal defense restore")
        var normal: Dictionary = debuff_runner.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(debuff_runner.restore_runtime_snapshot(with_debuff), "lower defense restore")
        var lowered: Dictionary = debuff_runner.perform_action({"type": "attack", "target_id": DUMMY})
        _expect(int(lowered.get("damage", 0)) > int(normal.get("damage", 0)), "defense_down did not increase damage")

    _case("round-end statuses fully settle before the result check")
    var simultaneous_context := _new_context("simultaneous_round_end")
    if not simultaneous_context.is_empty():
        var simultaneous_runner: RefCounted = simultaneous_context["combat"]
        _expect_ok(simultaneous_runner.start_combat(BASIC, 6605), "simultaneous status combat start")
        var simultaneous_setup: Dictionary = simultaneous_runner.export_runtime_snapshot()
        simultaneous_setup["runtime"]["units"][PLAYER]["hp"] = 1.0
        simultaneous_setup["runtime"]["units"][DUMMY]["hp"] = 1.0
        for unit_id: String in [PLAYER, DUMMY]:
            simultaneous_setup["runtime"]["units"][unit_id]["statuses"]["poison"] = {
                "status_id": "poison",
                "duration": 1,
                "stacks": 1,
                "magnitude": 1.0,
                "source_id": "TEST_STATUS_SETUP",
                "applied_round": 1,
            }
        simultaneous_setup["runtime"]["turn_order"] = [PLAYER]
        simultaneous_setup["runtime"]["turn_index"] = 0
        _expect(simultaneous_runner.restore_runtime_snapshot(simultaneous_setup), "simultaneous status setup")
        _expect_ok(simultaneous_runner.perform_action({"type": "defend"}), "action ending simultaneous status round")
        var simultaneous_result: Dictionary = simultaneous_runner.get_last_result()
        _expect(PLAYER in simultaneous_result.get("defeated_units", []), "player poison was not settled")
        _expect(DUMMY in simultaneous_result.get("defeated_units", []), "enemy poison was skipped before result evaluation")


func _test_inspect_cache_and_seeded_result() -> void:
    _case("deterministic inspect reveals registered information")
    var context := _new_context("inspect")
    if context.is_empty():
        return
    var runner: RefCounted = context["combat"]
    _expect_ok(runner.start_combat(BASIC, 7701), "inspect combat start")
    _force_turn(runner, PLAYER, [PLAYER, COMPANION, DUMMY])
    var first: Dictionary = runner.perform_action({"type": "inspect", "target_id": DUMMY})
    _expect_ok(first, "first inspect")
    _expect(first.get("outcome") == "success", "registered deterministic inspect did not succeed")
    _expect(first.get("reveal") == "synthetic_low_defense", "inspect returned the wrong registered reveal")
    _expect(not str(first.get("public_info", "")).is_empty(), "inspect omitted registered public enemy information")

    _case("repeat inspect returns no new findings without reroll farming")
    _force_turn(runner, PLAYER, [PLAYER, COMPANION, DUMMY])
    var second: Dictionary = runner.perform_action({"type": "inspect", "target_id": DUMMY})
    _expect_ok(second, "repeat inspect")
    _expect(second.get("outcome") == "no_new_findings", "repeat inspect returned another rewardable finding")
    _expect(second.has("cached_result"), "repeat inspect did not identify the cached result")
    _expect(runner.export_runtime_snapshot()["runtime"]["inspect_cache"].size() == 1, "repeat inspect created duplicate cache entries")

    _case("seeded inspect is reproducible")
    var one := _new_context("seeded_inspect_one")
    var two := _new_context("seeded_inspect_two")
    if not one.is_empty() and not two.is_empty():
        var runner_one: RefCounted = one["combat"]
        var runner_two: RefCounted = two["combat"]
        _expect_ok(runner_one.start_combat(BOSS, 7702), "first seeded inspect start")
        _expect_ok(runner_two.start_combat(BOSS, 7702), "second seeded inspect start")
        for seeded_runner: RefCounted in [runner_one, runner_two]:
            var setup: Dictionary = seeded_runner.export_runtime_snapshot()
            setup["runtime"]["units"][BOSS_PLAYER]["insight"] = 2.0
            setup["runtime"]["turn_order"] = [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY]
            setup["runtime"]["turn_index"] = 0
            _expect(seeded_runner.restore_runtime_snapshot(setup), "seeded inspect setup")
        var result_one: Dictionary = runner_one.perform_action({"type": "inspect", "target_id": BOSS_ENEMY})
        var result_two: Dictionary = runner_two.perform_action({"type": "inspect", "target_id": BOSS_ENEMY})
        _expect(result_one.get("roll") == result_two.get("roll"), "same seed produced different inspect roll")
        _expect(result_one.get("outcome") == result_two.get("outcome"), "same seed produced different inspect outcome")
        if result_one.get("outcome") == "no_new_findings":
            _expect(str(result_one.get("reveal", "")).is_empty(), "failed inspect leaked its registered reveal")

    _case("no-findings inspect never leaks its registered reveal")
    var no_findings_context := _new_context("inspect_no_findings")
    if not no_findings_context.is_empty():
        var no_findings_runner: RefCounted = no_findings_context["combat"]
        _expect_ok(no_findings_runner.start_combat(PARTIAL, 7703), "no-findings inspect start")
        _force_turn(no_findings_runner, PARTIAL_PLAYER, [PARTIAL_PLAYER, PARTIAL_DUMMY])
        var no_findings: Dictionary = no_findings_runner.perform_action({"type": "inspect", "target_id": PARTIAL_DUMMY})
        _expect(no_findings.get("outcome") == "no_new_findings", "no-findings fixture returned the wrong outcome")
        _expect(str(no_findings.get("reveal", "")).is_empty(), "no-findings inspect leaked hidden mechanism text")

    _case("inspect cache is scoped by boss phase")
    var phase_cache_context := _new_context("inspect_phase_cache")
    if not phase_cache_context.is_empty():
        var phase_cache_runner: RefCounted = phase_cache_context["combat"]
        _expect_ok(phase_cache_runner.start_combat(BOSS, 7704), "phase-scoped inspect start")
        var phase_cache_setup: Dictionary = phase_cache_runner.export_runtime_snapshot()
        phase_cache_setup["runtime"]["units"][BOSS_PLAYER]["insight"] = 2.0
        phase_cache_setup["runtime"]["turn_order"] = [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY]
        phase_cache_setup["runtime"]["turn_index"] = 0
        _expect(phase_cache_runner.restore_runtime_snapshot(phase_cache_setup), "phase-scoped inspect setup")
        _expect_ok(phase_cache_runner.perform_action({"type": "inspect", "target_id": BOSS_ENEMY}), "opening phase inspect")
        var pressure_setup: Dictionary = phase_cache_runner.export_runtime_snapshot()
        pressure_setup["runtime"]["units"][BOSS_ENEMY]["hp"] = 100.0
        pressure_setup["runtime"]["turn_order"] = [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY]
        pressure_setup["runtime"]["turn_index"] = 0
        _expect(phase_cache_runner.restore_runtime_snapshot(pressure_setup), "inspect pressure phase setup")
        _expect_ok(phase_cache_runner.perform_action({"type": "defend"}), "action entering pressure phase before re-inspect")
        _force_turn(phase_cache_runner, BOSS_PLAYER, [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY])
        var phase_inspect: Dictionary = phase_cache_runner.perform_action({"type": "inspect", "target_id": BOSS_ENEMY})
        _expect_ok(phase_inspect, "pressure phase inspect")
        _expect(not phase_inspect.has("cached_result"), "opening-phase cache incorrectly blocked pressure-phase inspection")


func _test_enemy_ai_and_companion_tendency() -> void:
    _case("enemy AI selects a legal weighted action deterministically")
    var first := _new_context("ai_seed_one")
    var second := _new_context("ai_seed_two")
    if first.is_empty() or second.is_empty():
        return
    var first_runner: RefCounted = first["combat"]
    var second_runner: RefCounted = second["combat"]
    _expect_ok(first_runner.start_combat(BASIC, 8801), "first AI combat start")
    _expect_ok(second_runner.start_combat(BASIC, 8801), "second AI combat start")
    _force_turn(first_runner, DUMMY, [DUMMY, PLAYER, COMPANION])
    _force_turn(second_runner, DUMMY, [DUMMY, PLAYER, COMPANION])
    var first_action: Dictionary = first_runner.run_auto_turn()
    var second_action: Dictionary = second_runner.run_auto_turn()
    _expect_ok(first_action, "first enemy AI action")
    _expect_ok(second_action, "second enemy AI action")
    _expect(first_action.get("action_type") == second_action.get("action_type"), "same seed changed AI action type")
    _expect(first_action.get("skill_id", "") == second_action.get("skill_id", ""), "same seed changed AI skill selection")
    _expect(first_action.get("target_id", "") == PLAYER, "basic enemy did not target its only legal player priority")

    _case("conditional AI action is unavailable above its HP threshold")
    var high_context := _new_context("ai_high_hp")
    if not high_context.is_empty():
        var high_runner: RefCounted = high_context["combat"]
        _expect_ok(high_runner.start_combat(SOLO, 8802), "high-HP AI start")
        _force_turn(high_runner, BRUTE, [BRUTE, SOLO_PLAYER])
        var high_action: Dictionary = high_runner.run_auto_turn()
        _expect(high_action.get("skill_id", "") != STUN_BLOW, "HP-threshold stun was selected above its threshold")

    _case("conditional AI action can be selected below its HP threshold")
    var saw_stun := false
    for seed: int in range(8803, 8827):
        var low_context := _new_context("ai_low_hp_%d" % seed)
        if low_context.is_empty():
            continue
        var low_runner: RefCounted = low_context["combat"]
        if not bool(low_runner.start_combat(SOLO, seed).get("ok", false)):
            continue
        var low_setup: Dictionary = low_runner.export_runtime_snapshot()
        low_setup["runtime"]["units"][BRUTE]["hp"] = 40.0
        low_setup["runtime"]["turn_order"] = [BRUTE, SOLO_PLAYER]
        low_setup["runtime"]["turn_index"] = 0
        if not low_runner.restore_runtime_snapshot(low_setup):
            continue
        var low_action: Dictionary = low_runner.run_auto_turn()
        if low_action.get("skill_id", "") == STUN_BLOW:
            saw_stun = true
            break
    _expect(saw_stun, "conditional stun was never selectable below its HP threshold")

    _case("AI target priority chooses the lowest-HP ally")
    var target_context := _new_context("ai_target_priority")
    if not target_context.is_empty():
        var target_runner: RefCounted = target_context["combat"]
        _expect_ok(target_runner.start_combat(BOSS, 8828), "AI target-priority start")
        var setup: Dictionary = target_runner.export_runtime_snapshot()
        setup["runtime"]["units"][BOSS_PLAYER]["hp"] = 20.0
        setup["runtime"]["units"][BOSS_COMPANION]["hp"] = 80.0
        setup["runtime"]["units"][BOSS_ENEMY]["ai_actions"] = [{
            "action_id": "test_only_attack",
            "mode": "weighted_action",
            "action_type": "attack",
            "weight": 1.0,
            "conditions": [],
            "target_priority": "lowest_hp",
        }]
        setup["runtime"]["turn_order"] = [BOSS_ENEMY, BOSS_PLAYER, BOSS_COMPANION]
        setup["runtime"]["turn_index"] = 0
        _expect(target_runner.restore_runtime_snapshot(setup), "AI target-priority setup")
        var target_action: Dictionary = target_runner.run_auto_turn()
        _expect(target_action.get("target_id", "") == BOSS_PLAYER, "lowest-HP target priority selected the wrong ally")

    _case("AI falls back to a stable attack when configured actions are unusable")
    var fallback_context := _new_context("ai_unusable_fallback")
    if not fallback_context.is_empty():
        var fallback_runner: RefCounted = fallback_context["combat"]
        _expect_ok(fallback_runner.start_combat(SOLO, 8829), "AI fallback combat start")
        var fallback_setup: Dictionary = fallback_runner.export_runtime_snapshot()
        fallback_setup["runtime"]["units"][BRUTE]["ai_actions"] = [{
            "action_id": "cooling_skill_only",
            "mode": "weighted_action",
            "action_type": "skill",
            "weight": 1.0,
            "skill_id": STUN_BLOW,
            "conditions": [],
            "target_priority": "player",
        }]
        fallback_setup["runtime"]["units"][BRUTE]["cooldowns"][STUN_BLOW] = 2
        fallback_setup["runtime"]["turn_order"] = [BRUTE, SOLO_PLAYER]
        fallback_setup["runtime"]["turn_index"] = 0
        _expect(fallback_runner.restore_runtime_snapshot(fallback_setup), "AI fallback setup")
        var fallback_action: Dictionary = fallback_runner.run_auto_turn()
        _expect_ok(fallback_action, "AI fallback action")
        _expect(fallback_action.get("action_type") == "attack", "AI did not use its stable basic-attack fallback")

    _case("random-opponent condition and command share one selected target")
    var saw_conditioned_random_target := false
    for seed: int in range(8830, 8860):
        var random_context := _new_context("random_condition_target_%d" % seed)
        if random_context.is_empty():
            continue
        var random_runner: RefCounted = random_context["combat"]
        if not bool(random_runner.start_combat(BOSS, seed).get("ok", false)):
            continue
        var random_setup: Dictionary = random_runner.export_runtime_snapshot()
        random_setup["runtime"]["units"][BOSS_PLAYER]["hp"] = 20.0
        random_setup["runtime"]["units"][BOSS_COMPANION]["hp"] = 90.0
        random_setup["runtime"]["units"][BOSS_COMPANION]["statuses"]["poison"] = {
            "status_id": "poison", "duration": 2, "stacks": 1, "magnitude": 1.0,
            "source_id": BOSS_ENEMY, "applied_round": 1,
        }
        random_setup["runtime"]["units"][BOSS_ENEMY]["ai_actions"] = [{
            "action_id": "conditioned_random_attack",
            "mode": "conditional_action",
            "action_type": "attack",
            "weight": 1.0,
            "conditions": [{"type": "status", "subject": "target", "status_id": "poison", "present": true}],
            "target_priority": "random_opponent",
        }]
        random_setup["runtime"]["turn_order"] = [BOSS_ENEMY, BOSS_PLAYER, BOSS_COMPANION]
        random_setup["runtime"]["turn_index"] = 0
        if not random_runner.restore_runtime_snapshot(random_setup):
            continue
        var random_action: Dictionary = random_runner.run_auto_turn()
        if bool(random_action.get("ok", false)) and random_action.get("target_id") == BOSS_COMPANION:
            saw_conditioned_random_target = true
            break
    _expect(saw_conditioned_random_target, "random target condition never selected and acted on the same eligible companion")

    _case("companion weight queries do not consume combat randomness")
    var query_context := _new_context("companion_weight_rng")
    if not query_context.is_empty():
        var query_runner: RefCounted = query_context["combat"]
        _expect_ok(query_runner.start_combat(BASIC, 8861), "companion query combat start")
        var query_setup: Dictionary = query_runner.export_runtime_snapshot()
        query_setup["runtime"]["units"][COMPANION]["ai_actions"][0]["target_priority"] = "random_opponent"
        _expect(query_runner.restore_runtime_snapshot(query_setup), "companion query setup")
        var before_query: Dictionary = query_runner.export_runtime_snapshot()
        _expect_ok(query_runner.get_companion_action_weights(COMPANION, "offensive"), "companion random-target weight query")
        _expect(query_runner.export_runtime_snapshot() == before_query, "weight query advanced the combat random stream")

    _case("companion tendencies change data-driven weights")
    var tendency_context := _new_context("companion_tendency")
    if not tendency_context.is_empty():
        var tendency_runner: RefCounted = tendency_context["combat"]
        _expect_ok(tendency_runner.start_combat(BASIC, 8862), "companion tendency start")
        var offensive: Dictionary = tendency_runner.get_companion_action_weights(COMPANION, "offensive")
        var support: Dictionary = tendency_runner.get_companion_action_weights(COMPANION, "support")
        _expect_ok(offensive, "offensive companion weights")
        _expect_ok(support, "support companion weights")
        _expect(offensive.get("weights", {}) != support.get("weights", {}), "companion tendency did not change action weights")
        _force_turn(tendency_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        _expect_ok(tendency_runner.set_companion_tendency("support"), "set companion tendency")
        _expect_code(tendency_runner.set_companion_tendency("defensive"), "COMPANION_TENDENCY_INVALID", "second tendency in one round")


func _test_boss_and_event_phases() -> void:
    _case("boss activates the combat-start and HP phases once")
    var context := _new_context("boss_phases")
    if context.is_empty():
        return
    var runner: RefCounted = context["combat"]
    var recorder := SignalRecorder.new()
    recorder.bind(runner)
    _expect_ok(runner.start_combat(BOSS, 9901), "boss phase combat start")
    _expect(runner.export_runtime_snapshot()["runtime"]["current_phase_id"] == "opening", "boss did not enter its opening phase")
    var pressure: Dictionary = runner.export_runtime_snapshot()
    pressure["runtime"]["units"][BOSS_ENEMY]["hp"] = 100.0
    pressure["runtime"]["turn_order"] = [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY]
    pressure["runtime"]["turn_index"] = 0
    _expect(runner.restore_runtime_snapshot(pressure), "boss pressure setup")
    _expect_ok(runner.perform_action({"type": "defend"}), "action triggering boss pressure")
    _expect(runner.export_runtime_snapshot()["runtime"]["current_phase_id"] == "pressure", "boss did not enter HP threshold phase")
    _force_turn(runner, BOSS_PLAYER, [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY])
    _expect_ok(runner.perform_action({"type": "skill", "skill_id": BREAK_ARMOR, "target_id": BOSS_ENEMY}), "action triggering status phase")
    var phased: Dictionary = runner.export_runtime_snapshot()
    _expect(phased["runtime"]["current_phase_id"] == "exposed", "boss did not enter status-triggered phase")
    _expect(phased["runtime"]["triggered_phases"].size() == 3, "boss did not record exactly three one-shot phases")
    _expect(recorder.phases == ["opening", "pressure", "exposed"], "boss phase signals were not stable or ordered")

    _case("explicit event phase is data-driven and idempotent")
    var event_context := _new_context("event_phase")
    if not event_context.is_empty():
        var event_runner: RefCounted = event_context["combat"]
        _expect_ok(event_runner.start_combat(PARTIAL, 9902), "event phase combat start")
        var first: Dictionary = event_runner.trigger_phase_event("test_clock")
        var second: Dictionary = event_runner.trigger_phase_event("test_clock")
        _expect_ok(first, "first event phase trigger")
        _expect(bool(first.get("changed", false)), "first event phase trigger did not change phase")
        _expect(not bool(second.get("changed", true)), "repeat event phase trigger activated twice")
        _expect(first.get("current_phase_id") == "event_shift", "event phase entered the wrong phase")

    _case("defeated boss does not emit a post-death phase change")
    var defeated_phase_context := _new_context("defeated_boss_phase")
    if not defeated_phase_context.is_empty():
        var defeated_phase_runner: RefCounted = defeated_phase_context["combat"]
        var defeated_phase_recorder := SignalRecorder.new()
        defeated_phase_recorder.bind(defeated_phase_runner)
        _expect_ok(defeated_phase_runner.start_combat(BOSS, 9905), "defeated boss phase start")
        var defeated_phase_setup: Dictionary = defeated_phase_runner.export_runtime_snapshot()
        defeated_phase_setup["runtime"]["units"][BOSS_ENEMY]["hp"] = 1.0
        defeated_phase_setup["runtime"]["turn_order"] = [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY]
        defeated_phase_setup["runtime"]["turn_index"] = 0
        _expect(defeated_phase_runner.restore_runtime_snapshot(defeated_phase_setup), "defeated boss phase setup")
        _expect_ok(defeated_phase_runner.perform_action({"type": "attack", "target_id": BOSS_ENEMY}), "boss finishing attack")
        _expect(defeated_phase_recorder.phases == ["opening"], "boss emitted a phase transition after defeat")

    _case("HP phase trigger honors its registered comparison operator")
    var hp_operator_context := _new_context_with_combat_runtime_mutation(
        "hp_phase_operator",
        PARTIAL,
        func(runtime: Dictionary) -> void:
            runtime["phases"].append({
                "phase_id": "above_half",
                "target_unit_id": PARTIAL_DUMMY,
                "trigger": {"type": "hp_threshold", "unit_id": PARTIAL_PLAYER, "op": "gt", "value": 0.5},
                "skill_ids": [POWER_STRIKE],
                "stat_modifiers": [],
                "ai_weight_modifiers": {},
                "event_tag": "above_half",
            })
    )
    if not hp_operator_context.is_empty():
        var hp_operator_runner: RefCounted = hp_operator_context["combat"]
        _expect_ok(hp_operator_runner.start_combat(PARTIAL, 9903), "HP operator phase combat start")
        var hp_operator_setup: Dictionary = hp_operator_runner.export_runtime_snapshot()
        hp_operator_setup["runtime"]["turn_order"] = [PARTIAL_PLAYER, PARTIAL_DUMMY]
        hp_operator_setup["runtime"]["turn_index"] = 0
        _expect(hp_operator_runner.restore_runtime_snapshot(hp_operator_setup), "HP operator phase setup")
        _expect_ok(hp_operator_runner.perform_action({"type": "defend"}), "action triggering greater-than HP phase")
        _expect(hp_operator_runner.export_runtime_snapshot()["runtime"]["current_phase_id"] == "above_half", "HP phase ignored its greater-than operator")

    _case("status phase trigger honors present false")
    var absent_status_context := _new_context_with_combat_runtime_mutation(
        "absent_status_phase",
        PARTIAL,
        func(runtime: Dictionary) -> void:
            runtime["phases"].append({
                "phase_id": "poison_absent",
                "target_unit_id": PARTIAL_DUMMY,
                "trigger": {"type": "status", "unit_id": PARTIAL_DUMMY, "status_id": "poison", "present": false},
                "skill_ids": [POWER_STRIKE],
                "stat_modifiers": [],
                "ai_weight_modifiers": {},
                "event_tag": "poison_absent",
            })
    )
    if not absent_status_context.is_empty():
        var absent_status_runner: RefCounted = absent_status_context["combat"]
        _expect_ok(absent_status_runner.start_combat(PARTIAL, 9904), "absent-status phase combat start")
        var absent_status_setup: Dictionary = absent_status_runner.export_runtime_snapshot()
        absent_status_setup["runtime"]["turn_order"] = [PARTIAL_PLAYER, PARTIAL_DUMMY]
        absent_status_setup["runtime"]["turn_index"] = 0
        _expect(absent_status_runner.restore_runtime_snapshot(absent_status_setup), "absent-status phase setup")
        _expect_ok(absent_status_runner.perform_action({"type": "defend"}), "action triggering absent-status phase")
        _expect(absent_status_runner.export_runtime_snapshot()["runtime"]["current_phase_id"] == "poison_absent", "status phase ignored present false")


func _test_victory_defeat_retreat_and_partial_success() -> void:
    _case("victory result contains stable summary fields")
    var victory_context := _new_context("victory")
    if victory_context.is_empty():
        return
    var victory_runner: RefCounted = victory_context["combat"]
    _expect_ok(victory_runner.start_combat(BASIC, 10101), "victory combat start")
    var victory_setup: Dictionary = victory_runner.export_runtime_snapshot()
    victory_setup["runtime"]["units"][DUMMY]["hp"] = 1.0
    victory_setup["runtime"]["turn_order"] = [PLAYER, COMPANION, DUMMY]
    victory_setup["runtime"]["turn_index"] = 0
    _expect(victory_runner.restore_runtime_snapshot(victory_setup), "victory setup")
    var finishing_hit: Dictionary = victory_runner.perform_action({"type": "attack", "target_id": DUMMY})
    _expect_ok(finishing_hit, "victory finishing hit")
    var victory: Dictionary = victory_runner.get_last_result()
    _expect(victory.get("result_type") == "victory", "enemy defeat did not produce victory")
    for field: String in ["defeated_units", "surviving_units", "turns_elapsed", "rounds_elapsed", "consumed_items", "important_events", "continuation_tag", "random_state"]:
        _expect(victory.has(field), "victory result is missing %s" % field)
    _expect(victory.get("continuation_tag") == "test_basic_victory", "victory continuation tag was not data-driven")

    _case("player defeat produces a continuation result")
    var defeat_context := _new_context("defeat")
    if not defeat_context.is_empty():
        var defeat_runner: RefCounted = defeat_context["combat"]
        _expect_ok(defeat_runner.start_combat(SOLO, 10102), "defeat combat start")
        var defeat_setup: Dictionary = defeat_runner.export_runtime_snapshot()
        defeat_setup["runtime"]["units"][SOLO_PLAYER]["hp"] = 1.0
        defeat_setup["runtime"]["turn_order"] = [BRUTE, SOLO_PLAYER]
        defeat_setup["runtime"]["turn_index"] = 0
        _expect(defeat_runner.restore_runtime_snapshot(defeat_setup), "defeat setup")
        _expect_ok(defeat_runner.run_auto_turn(), "defeating attack")
        _expect(defeat_runner.get_last_result().get("result_type") == "defeat", "player defeat produced the wrong result")
        _expect(defeat_runner.get_last_result().get("continuation_tag") == "test_solo_defeat", "defeat continuation tag was not preserved")

    _case("guaranteed retreat ends combat with retreat")
    var retreat_context := _new_context("retreat_success")
    if not retreat_context.is_empty():
        var retreat_runner: RefCounted = retreat_context["combat"]
        _expect_ok(retreat_runner.start_combat(PARTIAL, 10103), "guaranteed retreat start")
        _force_turn(retreat_runner, PARTIAL_PLAYER, [PARTIAL_PLAYER, PARTIAL_DUMMY])
        var retreat: Dictionary = retreat_runner.perform_action({"type": "retreat"})
        _expect_ok(retreat, "guaranteed retreat action")
        _expect(bool(retreat.get("success", false)), "guaranteed retreat failed")
        _expect(retreat_runner.get_last_result().get("result_type") == "retreat", "successful retreat produced the wrong result")

    _case("forbidden retreat returns an explicit error")
    var forbidden_context := _new_context("retreat_forbidden")
    if not forbidden_context.is_empty():
        var forbidden_runner: RefCounted = forbidden_context["combat"]
        _expect_ok(forbidden_runner.start_combat(SOLO, 10104), "forbidden retreat start")
        _force_turn(forbidden_runner, SOLO_PLAYER, [SOLO_PLAYER, BRUTE])
        _expect_code(forbidden_runner.perform_action({"type": "retreat"}), "RETREAT_FORBIDDEN", "forbidden retreat")
        _expect(forbidden_runner.is_active(), "forbidden retreat ended combat")

    _case("failed retreat consumes a turn and combat continues")
    var saw_failed_retreat := false
    for seed: int in range(10105, 10125):
        var failed_context := _new_context("retreat_failure_%d" % seed)
        if failed_context.is_empty():
            continue
        var failed_runner: RefCounted = failed_context["combat"]
        if not bool(failed_runner.start_combat(BOSS, seed).get("ok", false)):
            continue
        _force_turn(failed_runner, BOSS_PLAYER, [BOSS_PLAYER, BOSS_COMPANION, BOSS_ENEMY])
        var failed: Dictionary = failed_runner.perform_action({"type": "retreat"})
        if bool(failed.get("ok", false)) and not bool(failed.get("success", true)):
            saw_failed_retreat = true
            _expect(bool(failed.get("consumed_turn", false)), "failed retreat did not report turn consumption")
            _expect(failed_runner.is_active(), "failed retreat ended combat")
            _expect(str(failed_runner.get_current_actor().get("unit_id", "")) == BOSS_COMPANION, "failed retreat did not advance turn")
            break
    _expect(saw_failed_retreat, "no deterministic seed exercised failed retreat")

    _case("round safety limit produces partial_success")
    var partial_context := _new_context_with_combat_runtime_mutation(
        "partial_success",
        PARTIAL,
        func(runtime: Dictionary) -> void:
            if not runtime.get("rules") is Dictionary:
                runtime["rules"] = {}
            runtime["rules"]["max_rounds"] = 1
    )
    if not partial_context.is_empty():
        var partial_runner: RefCounted = partial_context["combat"]
        _expect_ok(partial_runner.start_combat(PARTIAL, 10126), "partial-success combat start")
        var partial_setup: Dictionary = partial_runner.export_runtime_snapshot()
        partial_setup["runtime"]["turn_order"] = [PARTIAL_PLAYER]
        partial_setup["runtime"]["turn_index"] = 0
        _expect(partial_runner.restore_runtime_snapshot(partial_setup), "partial-success setup")
        _expect_ok(partial_runner.perform_action({"type": "defend"}), "action reaching round limit")
        _expect(partial_runner.get_last_result().get("result_type") == "partial_success", "round limit did not produce partial_success")
        _expect(partial_runner.get_last_result().get("continuation_tag") == "test_partial_success", "partial-success continuation tag was not preserved")


func _test_snapshot_persistence_policy_and_cleanup() -> void:
    _case("active combat explicitly forbids save, load, and backup restore")
    var context := _new_context("persistence_policy")
    if context.is_empty():
        return
    var runner: RefCounted = context["combat"]
    _expect_ok(runner.start_combat(BASIC, 11101), "persistence policy combat start")
    for operation: String in ["save", "auto_save", "quick_save", "load", "restore_backup"]:
        var policy: Dictionary = runner.get_persistence_policy(operation)
        _expect(not bool(policy.get("allowed", true)), "%s was allowed during active combat" % operation)
        _expect(policy.get("code") == "COMBAT_PERSISTENCE_FORBIDDEN", "%s returned the wrong persistence error" % operation)

    _case("runtime snapshot round-trips without aliasing")
    var original: Dictionary = runner.export_runtime_snapshot()
    var changed: Dictionary = original.duplicate(true)
    changed["runtime"]["units"][PLAYER]["hp"] = 33.0
    _expect(runner.restore_runtime_snapshot(changed), "changed snapshot restore")
    _expect(float(runner.get_unit_state(PLAYER).get("hp", 0.0)) == 33.0, "snapshot did not restore unit HP")
    _expect(runner.restore_runtime_snapshot(original), "original snapshot restore")
    _expect(runner.export_runtime_snapshot() == original, "snapshot round trip did not restore exact runtime")

    _case("invalid snapshot is rejected without polluting runtime")
    var before_invalid: Dictionary = runner.export_runtime_snapshot()
    var invalid: Dictionary = before_invalid.duplicate(true)
    invalid["snapshot_version"] = 999
    _expect(not runner.restore_runtime_snapshot(invalid), "unsupported snapshot version was accepted")
    _expect(runner.export_runtime_snapshot() == before_invalid, "invalid snapshot polluted active combat")

    _case("malformed snapshot internals fail explicitly and atomically")
    var invalid_result: Dictionary = before_invalid.duplicate(true)
    invalid_result["last_result"] = []
    var invalid_hp: Dictionary = before_invalid.duplicate(true)
    invalid_hp["runtime"]["units"][PLAYER]["hp"] = -1.0
    var invalid_status: Dictionary = before_invalid.duplicate(true)
    invalid_status["runtime"]["units"][PLAYER]["statuses"]["unknown_status"] = {
        "duration": 1, "stacks": 1,
    }
    var invalid_definition: Dictionary = before_invalid.duplicate(true)
    invalid_definition["runtime"]["definition"]["retreat"]["allowed"] = false
    var invalid_rules: Dictionary = before_invalid.duplicate(true)
    invalid_rules["runtime"]["rules"]["guard_damage_reduction"] = 0.99
    var invalid_outcomes: Dictionary = before_invalid.duplicate(true)
    invalid_outcomes["runtime"]["outcomes"]["victory"]["next"] = "injected"
    for malformed: Dictionary in [
        invalid_result, invalid_hp, invalid_status,
        invalid_definition, invalid_rules, invalid_outcomes,
    ]:
        _expect(not runner.restore_runtime_snapshot(malformed), "malformed snapshot internals were accepted")
        _expect(runner.last_error.get("code") == "COMBAT_SNAPSHOT_INVALID", "malformed snapshot returned the wrong error code")
        _expect(runner.export_runtime_snapshot() == before_invalid, "malformed snapshot polluted active combat")

    _case("combat end clears temporary runtime but retains its result")
    var aborted: Dictionary = runner.abort_combat("partial_success", "test_abort_continuation")
    _expect(aborted.get("result_type") == "partial_success", "abort did not preserve requested result")
    var finished_snapshot: Dictionary = runner.export_runtime_snapshot()
    _expect(not bool(finished_snapshot.get("active", true)), "finished snapshot remained active")
    _expect(finished_snapshot.get("runtime", {}) == {}, "finished combat retained temporary runtime")
    _expect(not runner.get_last_result().is_empty(), "finished combat lost its result")

    _case("persistence becomes available after combat")
    for operation: String in ["save", "auto_save", "quick_save", "load", "restore_backup"]:
        _expect(bool(runner.get_persistence_policy(operation).get("allowed", false)), "%s remained blocked after combat" % operation)


func _test_actual_save_manager_guard() -> void:
    _case("actual SaveManager blocks every persistence entry during combat")
    var context := _new_context("actual_save_guard")
    if context.is_empty():
        return
    var loader: RefCounted = context["loader"]
    var game_state: RefCounted = context["game_state"]
    var inventory: RefCounted = context["inventory"]
    var combat: RefCounted = context["combat"]
    var story := StoryRunnerClass.new()
    if not story.initialize(loader, game_state) or not story.restore_position("TEST_STORY_MINIMAL", "opening", false):
        _failures.append("StoryRunner could not initialize for actual SaveManager guard test: %s" % str(story.last_error))
        return
    var root := "user://combat_runner_guard_test"
    _remove_tree(root)
    var saves := root.path_join("saves")
    var backups := root.path_join("backups")
    var save_manager := SaveManagerClass.new()
    if not save_manager.initialize(
        loader,
        game_state,
        story,
        saves,
        backups,
        "combat-test",
        Callable(self, "_fixed_timestamp"),
        inventory,
    ):
        _failures.append("SaveManager could not initialize for combat guard test: %s" % str(save_manager.last_result))
        _remove_tree(root)
        return
    _expect(combat.bind_save_manager(save_manager), "CombatRunner could not bind actual SaveManager")
    _expect_ok(combat.start_combat(BASIC, 11201), "actual SaveManager guarded combat start")
    _expect(save_manager.has_save("auto"), "precombat automatic checkpoint was not written before activation")
    var blocked_results: Array[Dictionary] = [
        save_manager.save("manual_1"),
        save_manager.request_auto_save(),
        save_manager.request_quick_save(),
        save_manager.load("auto"),
        save_manager.restore_backup("auto"),
    ]
    var labels := ["manual save", "auto save", "quick save", "load", "backup restore"]
    for index: int in range(blocked_results.size()):
        _expect_code(blocked_results[index], SaveManagerClass.SAVE_RUNTIME_BLOCKED, labels[index])
        _expect(blocked_results[index].get("guard_code") == "COMBAT_PERSISTENCE_FORBIDDEN", "%s lost the CombatRunner guard code" % labels[index])
    combat.abort_combat("partial_success", "save_guard_cleanup")
    _expect_ok(save_manager.save("manual_1"), "manual save after combat")
    _expect(combat.bind_save_manager(null), "CombatRunner could not release actual SaveManager guard")
    _remove_tree(root)


func _test_errors_signals_and_module_boundaries() -> void:
    _case("illegal actor, target, and action return stable errors atomically")
    var context := _new_context("errors")
    if context.is_empty():
        return
    var runner: RefCounted = context["combat"]
    _expect_ok(runner.start_combat(BASIC, 12101), "error contract combat start")
    _force_turn(runner, PLAYER, [PLAYER, COMPANION, DUMMY])
    var before: Dictionary = runner.export_runtime_snapshot()
    _expect_code(runner.perform_action({"type": "dance"}), "COMBAT_ACTION_INVALID", "unknown action")
    _expect_code(runner.perform_action({"type": "attack", "actor_id": DUMMY, "target_id": PLAYER}), "COMBAT_ACTOR_INVALID", "out-of-turn actor")
    _expect_code(runner.perform_action({"type": "attack", "target_id": COMPANION}), "COMBAT_TARGET_INVALID", "same-team target")
    _expect(runner.export_runtime_snapshot() == before, "illegal actions changed combat runtime")

    _case("public actions cannot control companion or enemy turns")
    var control_context := _new_context("control_authority")
    if not control_context.is_empty():
        var control_runner: RefCounted = control_context["combat"]
        _expect_ok(control_runner.start_combat(BASIC, 12104), "control authority combat start")
        _force_turn(control_runner, COMPANION, [COMPANION, DUMMY, PLAYER])
        var companion_before: Dictionary = control_runner.export_runtime_snapshot()
        _expect_code(
            control_runner.perform_action({"type": "attack", "target_id": DUMMY}),
            "COMBAT_ACTOR_CONTROL_FORBIDDEN",
            "direct companion control",
        )
        _expect(control_runner.export_runtime_snapshot() == companion_before, "direct companion control changed runtime")
        _force_turn(control_runner, DUMMY, [DUMMY, PLAYER, COMPANION])
        var enemy_before: Dictionary = control_runner.export_runtime_snapshot()
        _expect_code(
            control_runner.perform_action({"type": "retreat"}),
            "COMBAT_ACTOR_CONTROL_FORBIDDEN",
            "direct enemy control",
        )
        _expect(control_runner.export_runtime_snapshot() == enemy_before, "direct enemy control changed runtime")
        _expect_ok(control_runner.run_auto_turn(), "enemy AI remains available through the automatic entry point")

    _case("signals expose lifecycle without requiring UI nodes")
    var signal_context := _new_context("signals")
    if not signal_context.is_empty():
        var signal_runner: RefCounted = signal_context["combat"]
        var recorder := SignalRecorder.new()
        recorder.bind(signal_runner)
        _expect_ok(signal_runner.start_combat(BASIC, 12102), "signal combat start")
        _force_turn(signal_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        signal_runner.perform_action({"type": "attack", "target_id": DUMMY})
        _force_turn(signal_runner, PLAYER, [PLAYER, COMPANION, DUMMY])
        signal_runner.perform_action({"type": "defend"})
        signal_runner.perform_action({"type": "unknown"})
        signal_runner.abort_combat("partial_success", "signal_test")
        for signal_name: String in ["checkpoint", "started", "round", "turn", "action", "damage", "status", "phase", "finished", "error"]:
            _expect(int(recorder.counts[signal_name]) >= 1, "expected %s signal was not emitted" % signal_name)
        _expect(recorder.last_finished.get("continuation_tag") == "signal_test", "finish signal lost continuation data")

    _case("CombatRunner has no direct StoryRunner or QuestManager dependency")
    var source := _read_text("res://src/core/combat_runner.gd")
    _expect(source.find("story_runner") == -1 and source.find("StoryRunner") == -1, "CombatRunner directly depends on StoryRunner")
    _expect(source.find("quest_manager") == -1 and source.find("QuestManager") == -1, "CombatRunner directly depends on QuestManager")

    _case("CombatRunner has no concrete UI control dependency")
    _expect(source.find("extends Control") == -1, "CombatRunner extends a UI Control")
    _expect(source.find("get_node(") == -1 and source.find("$MainUI") == -1, "CombatRunner directly locates UI nodes")

    _case("precombat checkpoint is requested before runtime activation")
    var checkpoint_context := _new_context("checkpoint_signal")
    if not checkpoint_context.is_empty():
        var checkpoint_runner: RefCounted = checkpoint_context["combat"]
        var checkpoint_recorder := SignalRecorder.new()
        checkpoint_recorder.bind(checkpoint_runner)
        _expect_ok(checkpoint_runner.start_combat(BASIC, 12103), "checkpoint signal combat start")
        _expect(checkpoint_recorder.counts["checkpoint"] == 1, "precombat checkpoint was not requested exactly once")
        _expect(checkpoint_context["checkpoint_save_manager"].checkpoint_count == 1, "precombat checkpoint was not durably acknowledged")

    _case("combat start fails when no checkpoint manager is bound")
    var unbound_context := _new_context("checkpoint_required")
    if not unbound_context.is_empty():
        var unbound_runner: RefCounted = unbound_context["combat"]
        _expect(unbound_runner.bind_save_manager(null), "test could not unbind checkpoint manager")
        _expect_code(
            unbound_runner.start_combat(BASIC, 12105),
            "COMBAT_CHECKPOINT_FAILED",
            "unbound checkpoint start",
        )
        _expect(not unbound_runner.is_active(), "combat became active without a successful precombat checkpoint")


func _new_context(case_name: String) -> Dictionary:
    var loader := FixtureContentLoader.new(_states, _items, _combats, _enemies, _skills, _registry, _story)
    var game_state := GameStateClass.new()
    if not game_state.initialize_from_content_loader(loader):
        _failures.append("GameState initialization failed for %s: %s" % [case_name, str(game_state.last_error)])
        return {}
    var inventory := InventoryManagerClass.new()
    if not inventory.initialize(loader, game_state, 12):
        _failures.append("InventoryManager initialization failed for %s: %s" % [case_name, str(inventory.last_error)])
        return {}
    var combat := CombatRunnerClass.new()
    if not combat.initialize(loader, game_state, inventory):
        _failures.append("CombatRunner initialization failed for %s: %s" % [case_name, str(combat.last_error)])
        return {}
    var checkpoint_save_manager := CheckpointSaveManager.new()
    if not combat.bind_save_manager(checkpoint_save_manager):
        _failures.append("CombatRunner checkpoint binding failed for %s: %s" % [case_name, str(combat.last_error)])
        return {}
    return {
        "loader": loader,
        "game_state": game_state,
        "inventory": inventory,
        "combat": combat,
        "checkpoint_save_manager": checkpoint_save_manager,
    }


func _new_context_with_player_skills(
    case_name: String,
    combat_id: String,
    skill_ids: Array,
    skill_overrides: Dictionary = {},
) -> Dictionary:
    var original_combats := _combats
    var original_skills := _skills
    _combats = _combats.duplicate(true)
    _skills = _skills.duplicate(true)
    for combat: Dictionary in _combats:
        if str(combat.get("combat_id", "")) == combat_id:
            combat["runtime"]["player_unit"]["skill_ids"] = skill_ids.duplicate(true)
            break
    for skill: Dictionary in _skills:
        var skill_id := str(skill.get("skill_id", ""))
        if not skill_overrides.has(skill_id):
            continue
        var overrides: Dictionary = skill_overrides[skill_id]
        for key: Variant in overrides.keys():
            skill[key] = overrides[key].duplicate(true) if overrides[key] is Array or overrides[key] is Dictionary else overrides[key]
    var context := _new_context(case_name)
    _combats = original_combats
    _skills = original_skills
    return context


func _new_context_with_status_override(
    case_name: String,
    status_id: String,
    overrides: Dictionary,
) -> Dictionary:
    var original_registry := _registry
    _registry = _registry.duplicate(true)
    for status: Dictionary in _registry.get("status_definitions", []):
        if str(status.get("status_id", "")) != status_id:
            continue
        for key: Variant in overrides.keys():
            status[key] = overrides[key].duplicate(true) if overrides[key] is Array or overrides[key] is Dictionary else overrides[key]
        break
    var context := _new_context(case_name)
    _registry = original_registry
    return context


func _new_context_with_equal_agility(case_name: String) -> Dictionary:
    var original_combats := _combats
    _combats = _combats.duplicate(true)
    for combat: Dictionary in _combats:
        if str(combat.get("combat_id", "")) != BASIC:
            continue
        combat["runtime"]["player_unit"]["agility"] = 10
        for companion: Dictionary in combat["runtime"].get("companion_units", []):
            companion["agility"] = 10
        for enemy_instance: Dictionary in combat["runtime"].get("enemy_instances", []):
            enemy_instance["agility"] = 10
        break
    var context := _new_context(case_name)
    _combats = original_combats
    return context


func _new_context_with_enemy_ai(
    case_name: String,
    enemy_id: String,
    ai_actions: Array,
    stat_overrides: Dictionary = {},
) -> Dictionary:
    var original_enemies := _enemies
    _enemies = _enemies.duplicate(true)
    for enemy: Dictionary in _enemies:
        if str(enemy.get("enemy_id", "")) != enemy_id:
            continue
        if enemy.get("runtime") is Dictionary:
            enemy["runtime"]["ai_actions"] = ai_actions.duplicate(true)
        else:
            enemy["ai_actions"] = ai_actions.duplicate(true)
        for key: Variant in stat_overrides.keys():
            enemy[key] = stat_overrides[key]
        break
    var context := _new_context(case_name)
    _enemies = original_enemies
    return context


func _new_context_with_combat_runtime_mutation(
    case_name: String,
    combat_id: String,
    mutator: Callable,
) -> Dictionary:
    var original_combats := _combats
    _combats = _combats.duplicate(true)
    for combat: Dictionary in _combats:
        if str(combat.get("combat_id", "")) != combat_id:
            continue
        mutator.call(combat["runtime"])
        break
    var context := _new_context(case_name)
    _combats = original_combats
    return context


func _force_turn(runner: RefCounted, unit_id: String, order: Array = []) -> bool:
    var snapshot: Dictionary = runner.export_runtime_snapshot()
    if not bool(snapshot.get("active", false)):
        _failures.append("cannot force turn for %s because combat is inactive" % unit_id)
        return false
    var requested_order: Array = order.duplicate(true) if not order.is_empty() else snapshot["runtime"]["turn_order"].duplicate(true)
    var index := requested_order.find(unit_id)
    if index < 0:
        _failures.append("forced turn order does not contain %s" % unit_id)
        return false
    snapshot["runtime"]["turn_order"] = requested_order
    snapshot["runtime"]["turn_index"] = index
    if not runner.restore_runtime_snapshot(snapshot):
        _failures.append("CombatRunner rejected forced public snapshot for %s: %s" % [unit_id, str(runner.last_error)])
        return false
    return true


func _item_quantity(inventory: RefCounted, item_id: String) -> int:
    var result: Dictionary = inventory.get_item_quantity(item_id, "all")
    _expect_ok(result, "item quantity query for %s" % item_id)
    return int(result.get("quantity", -1))


func _load_fixtures() -> bool:
    var state_document := _read_json(STATE_FIXTURE)
    var story_state_document := _read_json(STORY_STATE_FIXTURE)
    var item_document := _read_json(ITEM_FIXTURE)
    var combat_document := _read_json(COMBAT_FIXTURE)
    var enemy_document := _read_json(ENEMY_FIXTURE)
    var skill_document := _read_json(SKILL_FIXTURE)
    var story_document := _read_json(STORY_FIXTURE)
    if (
        not state_document.get("states") is Array
        or not story_state_document.get("states") is Array
        or not item_document.get("items") is Array
        or not combat_document.get("combats") is Array
        or not combat_document.get("runtime") is Dictionary
        or not enemy_document.get("enemies") is Array
        or not skill_document.get("skills") is Array
        or not story_document.get("nodes") is Array
    ):
        _failures.append("combat fixture documents have an invalid root shape")
        return false
    _states = state_document["states"].duplicate(true)
    _states.append_array(story_state_document["states"])
    _items = item_document["items"]
    _combats = combat_document["combats"]
    _enemies = enemy_document["enemies"]
    _skills = skill_document["skills"]
    _registry = combat_document["runtime"]
    _story = story_document
    return true


func _run_full_solo(runner: RefCounted) -> Dictionary:
    var safety := 0
    while runner.is_active() and safety < 64:
        var actor: Dictionary = runner.get_current_actor()
        var result: Dictionary
        if str(actor.get("role", "")) == "player":
            result = runner.perform_action({"type": "attack", "target_id": BRUTE})
        else:
            result = runner.run_auto_turn()
        if not bool(result.get("ok", false)):
            _failures.append("full solo combat action failed: %s" % str(result))
            break
        safety += 1
    _expect(not runner.is_active(), "full solo combat did not terminate inside the safety bound")
    return runner.get_last_result()


func _fixed_timestamp() -> String:
    return "2026-01-02T03:04:05Z"


func _remove_tree(path: String) -> void:
    var absolute := ProjectSettings.globalize_path(path)
    if not DirAccess.dir_exists_absolute(absolute):
        return
    var directory := DirAccess.open(absolute)
    if directory == null:
        return
    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        var child := absolute.path_join(entry)
        if directory.current_is_dir():
            _remove_tree(child)
        else:
            DirAccess.remove_absolute(child)
        entry = directory.get_next()
    directory.list_dir_end()
    DirAccess.remove_absolute(absolute)


func _read_json(path: String) -> Dictionary:
    var text := _read_text(path)
    if text.is_empty():
        return {}
    var parsed: Variant = JSON.parse_string(text)
    if not parsed is Dictionary:
        _failures.append("fixture JSON root is not an object: %s" % path)
        return {}
    return parsed


func _read_text(path: String) -> String:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _failures.append("could not read fixture or source: %s" % path)
        return ""
    var text := file.get_as_text()
    file.close()
    return text


func _case(_label: String) -> void:
    _scenario_count += 1


func _expect_ok(result: Dictionary, label: String) -> void:
    _expect(bool(result.get("ok", false)), "%s failed: %s" % [label, str(result)])


func _expect_code(result: Dictionary, code: String, label: String) -> void:
    _expect(not bool(result.get("ok", true)), "%s unexpectedly succeeded" % label)
    _expect(str(result.get("code", "")) == code, "%s returned %s instead of %s" % [label, str(result.get("code", "")), code])


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    if _failures.is_empty():
        print("COMBAT_RUNNER_TESTS_OK:%d_SCENARIOS" % _scenario_count)
        quit(0)
        return
    for failure: String in _failures:
        printerr("COMBAT_RUNNER_TEST_FAILURE:%s" % failure)
    printerr("COMBAT_RUNNER_TESTS_FAILED:%d_SCENARIOS:%d_FAILURES" % [_scenario_count, _failures.size()])
    quit(1)
