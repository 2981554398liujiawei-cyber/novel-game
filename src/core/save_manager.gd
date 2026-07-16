extends RefCounted

signal save_completed(result: Dictionary)
signal load_completed(result: Dictionary)

const JsonSchemaValidatorClass = preload("res://src/core/json_schema_validator.gd")
const GameStateClass = preload("res://src/core/game_state.gd")
const InventoryManagerClass = preload("res://src/core/inventory_manager.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")

const SAVE_SCHEMA_VERSION := "1.1.0"
const CURRENT_SAVE_VERSION := 1
const DEFAULT_GAME_VERSION := "0.1.0"
const SLOT_IDS := ["manual_1", "manual_2", "manual_3", "auto", "quick"]
const AUTO_SLOT := "auto"
const QUICK_SLOT := "quick"

const SAVE_NOT_FOUND := "SAVE_NOT_FOUND"
const SAVE_JSON_INVALID := "SAVE_JSON_INVALID"
const SAVE_SCHEMA_INVALID := "SAVE_SCHEMA_INVALID"
const SAVE_VERSION_UNSUPPORTED := "SAVE_VERSION_UNSUPPORTED"
const SAVE_STATE_INVALID := "SAVE_STATE_INVALID"
const SAVE_INVENTORY_INVALID := "SAVE_INVENTORY_INVALID"
const SAVE_STORY_INVALID := "SAVE_STORY_INVALID"
const SAVE_WRITE_FAILED := "SAVE_WRITE_FAILED"
const SAVE_RESTORE_FAILED := "SAVE_RESTORE_FAILED"
const SAVE_NOT_INITIALIZED := "SAVE_NOT_INITIALIZED"
const SAVE_RUNTIME_BLOCKED := "SAVE_RUNTIME_BLOCKED"

var last_result: Dictionary = {}

var _game_state: RefCounted
var _inventory_manager: RefCounted
var _story_runner: RefCounted
var _content_loader: RefCounted
var _save_root := "user://saves"
var _backup_root := "user://backups"
var _game_version := DEFAULT_GAME_VERSION
var _playtime_seconds := 0.0
var _random_state: Dictionary = {"seed": 0}
var _clock_provider: Callable
var _schema: Dictionary = {}
var _schema_validator := JsonSchemaValidatorClass.new()
var _initialized := false
var _runtime_guard: WeakRef


func initialize(
    content_loader: RefCounted,
    game_state: RefCounted,
    story_runner: RefCounted,
    save_root: String = "user://saves",
    backup_root: String = "user://backups",
    game_version: String = "",
    clock_provider: Callable = Callable(),
    inventory_manager: RefCounted = null,
) -> bool:
    _initialized = false
    _content_loader = null
    _game_state = null
    _inventory_manager = null
    _story_runner = null
    _schema = {}
    _playtime_seconds = 0.0
    _random_state = {"seed": 0}
    _runtime_guard = null
    if content_loader == null or not content_loader.has_method("get_state_definitions") or not content_loader.has_method("get_story"):
        _set_last_result(_result(false, SAVE_SCHEMA_INVALID, "ContentLoader does not provide state and story data"))
        return false
    if (
        game_state == null
        or not game_state.has_method("export_snapshot")
        or not game_state.has_method("validate_snapshot")
        or not game_state.has_method("restore_snapshot")
        or not game_state.has_method("create_runtime_checkpoint")
        or not game_state.has_method("restore_runtime_checkpoint")
        or not game_state.has_method("emit_changes_from_checkpoint")
    ):
        _set_last_result(_result(false, SAVE_STATE_INVALID, "GameState does not provide snapshot interfaces"))
        return false
    if (
        story_runner == null
        or not story_runner.has_method("get_current_position")
        or not story_runner.has_method("is_valid_position")
        or not story_runner.has_method("restore_position")
        or not story_runner.has_method("create_runtime_checkpoint")
        or not story_runner.has_method("restore_runtime_checkpoint")
        or not story_runner.has_method("emit_position_restored")
    ):
        _set_last_result(_result(false, SAVE_STORY_INVALID, "StoryRunner does not provide position interfaces"))
        return false
    if inventory_manager != null:
        for method_name: String in [
            "get_capacity", "export_snapshot", "validate_snapshot", "restore_snapshot",
            "create_runtime_checkpoint", "restore_runtime_checkpoint", "emit_changes_from_checkpoint",
        ]:
            if not inventory_manager.has_method(method_name):
                _set_last_result(_result(
                    false,
                    SAVE_INVENTORY_INVALID,
                    "InventoryManager does not provide '%s'" % method_name,
                ))
                return false
        if not content_loader.has_method("get_item_definitions"):
            _set_last_result(_result(false, SAVE_INVENTORY_INVALID, "ContentLoader does not provide item definitions"))
            return false

    var normalized_save_root := _normalize_root(save_root)
    var normalized_backup_root := _normalize_root(backup_root)
    if not _is_allowed_storage_root(normalized_save_root) or not _is_allowed_storage_root(normalized_backup_root):
        _set_last_result(_result(false, SAVE_WRITE_FAILED, "Save paths must be writable user paths outside the installation directory"))
        return false

    _save_root = normalized_save_root
    _backup_root = normalized_backup_root
    _game_version = game_version if not game_version.is_empty() else str(
        ProjectSettings.get_setting("application/config/version", DEFAULT_GAME_VERSION)
    )
    _clock_provider = clock_provider
    if not _load_schema():
        return false
    if not _ensure_directories():
        _set_last_result(_result(false, SAVE_WRITE_FAILED, "Save directories could not be created"))
        return false
    _content_loader = content_loader
    _game_state = game_state
    _inventory_manager = inventory_manager
    _story_runner = story_runner
    _initialized = true
    _set_last_result(_result(true, "OK", "SaveManager initialized"))
    return true


func save(slot_id: String) -> Dictionary:
    return _save(slot_id, "save")


func _save(slot_id: String, operation: String) -> Dictionary:
    if not _initialized:
        return _emit_save_result(_not_initialized_result(slot_id))
    var runtime_block := _runtime_block_result(operation, slot_id)
    if not runtime_block.is_empty():
        return _emit_save_result(runtime_block)
    var slot_error := _validate_slot(slot_id)
    if not slot_error.is_empty():
        return _emit_save_result(slot_error)

    var position: Dictionary = _story_runner.call("get_current_position")
    var story_id := str(position.get("story_id", ""))
    var node_id := str(position.get("node_id", ""))
    if not bool(_story_runner.call("is_valid_position", story_id, node_id)):
        return _emit_save_result(_result(false, SAVE_STORY_INVALID, "Current StoryRunner position cannot be saved", slot_id))

    var inventory_snapshot: Dictionary = {}
    if _inventory_manager != null:
        inventory_snapshot = _inventory_manager.call("export_snapshot")
        if not bool(_inventory_manager.call("validate_snapshot", inventory_snapshot)):
            return _emit_save_result(_result(false, SAVE_INVENTORY_INVALID, "Current InventoryManager state cannot be saved", slot_id, {
                "details": _inventory_manager.get("last_error"),
            }))

    var now := _now_timestamp()
    if now.is_empty():
        return _emit_save_result(_result(false, SAVE_SCHEMA_INVALID, "Clock provider returned an empty timestamp", slot_id))
    var created_at := now
    if FileAccess.file_exists(get_save_path(slot_id)):
        var existing := _read_json_file(get_save_path(slot_id), slot_id)
        if bool(existing.get("ok", false)):
            created_at = str(existing["data"].get("created_at", now))

    var document := {
        "schema_version": SAVE_SCHEMA_VERSION,
        "save_version": CURRENT_SAVE_VERSION,
        "game_version": _game_version,
        "development_save": true,
        "created_at": created_at,
        "updated_at": now,
        "slot_id": slot_id,
        "playtime_seconds": _playtime_seconds,
        "current_story_id": story_id,
        "current_story_node_id": node_id,
        "game_state": _game_state.call("export_snapshot"),
        "random_state": _random_state.duplicate(true),
    }
    if _inventory_manager != null:
        document["inventory_state"] = inventory_snapshot
    var validation := _validate_document(document, slot_id)
    if not bool(validation.get("ok", false)):
        return _emit_save_result(validation)

    var write_result := _write_document_atomic(document, slot_id, true)
    if not bool(write_result.get("ok", false)):
        return _emit_save_result(write_result)
    write_result["metadata"] = _metadata_from_document(document, true)
    return _emit_save_result(write_result)


func load(slot_id: String) -> Dictionary:
    if not _initialized:
        return _emit_load_result(_not_initialized_result(slot_id))
    var runtime_block := _runtime_block_result("load", slot_id)
    if not runtime_block.is_empty():
        return _emit_load_result(runtime_block)
    var slot_error := _validate_slot(slot_id)
    if not slot_error.is_empty():
        return _emit_load_result(slot_error)
    var read_result := _read_json_file(get_save_path(slot_id), slot_id)
    if not bool(read_result.get("ok", false)):
        return _emit_load_result(read_result)
    var document: Dictionary = read_result["data"]
    var validation := _validate_document(document, slot_id, true)
    if not bool(validation.get("ok", false)):
        return _emit_load_result(validation)
    var apply_result := _apply_document(document, slot_id, validation["prepared_runtime"])
    if bool(apply_result.get("ok", false)):
        apply_result["metadata"] = _metadata_from_document(document, true)
    return _emit_load_result(apply_result)


func delete_save(slot_id: String) -> Dictionary:
    if not _initialized:
        return _set_last_result(_not_initialized_result(slot_id))
    var slot_error := _validate_slot(slot_id)
    if not slot_error.is_empty():
        return _set_last_result(slot_error)
    var paths := [get_save_path(slot_id), _temp_path(slot_id), get_backup_path(slot_id), _backup_temp_path(slot_id)]
    var found := false
    for path: String in paths:
        if FileAccess.file_exists(path):
            found = true
            if DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
                return _set_last_result(_result(false, SAVE_WRITE_FAILED, "Save file could not be deleted", slot_id))
    if not found:
        return _set_last_result(_result(false, SAVE_NOT_FOUND, "Save slot does not exist", slot_id))
    return _set_last_result(_result(true, "OK", "Save slot deleted", slot_id))


func list_saves() -> Dictionary:
    if not _initialized:
        return _set_last_result(_not_initialized_result())
    var saves: Array = []
    for slot_id: String in SLOT_IDS:
        var path := get_save_path(slot_id)
        if not FileAccess.file_exists(path):
            continue
        var read_result := _read_json_file(path, slot_id)
        if not bool(read_result.get("ok", false)):
            saves.append({
                "slot_id": slot_id,
                "valid": false,
                "error_code": str(read_result.get("code", SAVE_JSON_INVALID)),
                "backup_available": FileAccess.file_exists(get_backup_path(slot_id)),
            })
            continue
        var document: Dictionary = read_result["data"]
        var validation := _validate_document(document, slot_id)
        if not bool(validation.get("ok", false)):
            saves.append({
                "slot_id": slot_id,
                "valid": false,
                "error_code": str(validation.get("code", SAVE_SCHEMA_INVALID)),
                "backup_available": FileAccess.file_exists(get_backup_path(slot_id)),
            })
            continue
        saves.append(_metadata_from_document(document, true))
    return _set_last_result(_result(true, "OK", "Save slots listed", "", {"saves": saves}))


func has_save(slot_id: String) -> bool:
    return _initialized and slot_id in SLOT_IDS and FileAccess.file_exists(get_save_path(slot_id))


func restore_backup(slot_id: String) -> Dictionary:
    if not _initialized:
        return _emit_load_result(_not_initialized_result(slot_id))
    var runtime_block := _runtime_block_result("restore_backup", slot_id)
    if not runtime_block.is_empty():
        return _emit_load_result(runtime_block)
    var slot_error := _validate_slot(slot_id)
    if not slot_error.is_empty():
        return _emit_load_result(slot_error)
    var backup_path := get_backup_path(slot_id)
    var read_result := _read_json_file(backup_path, slot_id)
    if not bool(read_result.get("ok", false)):
        return _emit_load_result(read_result)
    var document: Dictionary = read_result["data"]
    var validation := _validate_document(document, slot_id, true)
    if not bool(validation.get("ok", false)):
        return _emit_load_result(validation)

    var write_result := _write_document_atomic(document, slot_id, false)
    if not bool(write_result.get("ok", false)):
        return _emit_load_result(_result(false, SAVE_RESTORE_FAILED, "Backup was valid but could not replace the main save", slot_id, {"cause": write_result}))
    var apply_result := _apply_document(document, slot_id, validation["prepared_runtime"])
    if not bool(apply_result.get("ok", false)):
        return _emit_load_result(apply_result)
    var result := _result(true, "OK", "Backup restored", slot_id, {"metadata": _metadata_from_document(document, true)})
    return _emit_load_result(result)


func request_auto_save() -> Dictionary:
    return _save(AUTO_SLOT, "auto_save")


func request_quick_save() -> Dictionary:
    return _save(QUICK_SLOT, "quick_save")


func create_precombat_checkpoint() -> Dictionary:
    return request_auto_save()


func set_runtime_guard(runtime_guard: RefCounted = null) -> Dictionary:
    if runtime_guard != null and not runtime_guard.has_method("get_persistence_policy"):
        return _set_last_result(_result(
            false,
            SAVE_SCHEMA_INVALID,
            "Runtime persistence guard does not provide get_persistence_policy(operation)",
        ))
    _runtime_guard = weakref(runtime_guard) if runtime_guard != null else null
    var message := "Runtime persistence guard cleared" if runtime_guard == null else "Runtime persistence guard set"
    return _set_last_result(_result(true, "OK", message))


func get_persistence_policy(operation: String) -> Dictionary:
    if _runtime_guard == null:
        return {
            "allowed": true,
            "code": "OK",
            "message": "Persistence operation allowed",
            "operation": operation,
        }

    var runtime_guard: Variant = _runtime_guard.get_ref()
    if runtime_guard == null:
        _runtime_guard = null
        return {
            "allowed": true,
            "code": "OK",
            "message": "Persistence operation allowed",
            "operation": operation,
        }
    var raw_policy: Variant = runtime_guard.call("get_persistence_policy", operation)
    if not raw_policy is Dictionary:
        return {
            "allowed": false,
            "code": SAVE_RUNTIME_BLOCKED,
            "message": "Runtime persistence guard returned an invalid policy",
            "operation": operation,
            "guard_code": "INVALID_POLICY",
        }

    var guard_policy: Dictionary = raw_policy
    if bool(guard_policy.get("allowed", false)):
        return {
            "allowed": true,
            "code": "OK",
            "message": str(guard_policy.get("message", "Persistence operation allowed")),
            "operation": operation,
            "guard_code": str(guard_policy.get("code", "OK")),
        }
    return {
        "allowed": false,
        "code": SAVE_RUNTIME_BLOCKED,
        "message": str(guard_policy.get("message", "Runtime state does not allow persistence")),
        "operation": operation,
        "guard_code": str(guard_policy.get("code", SAVE_RUNTIME_BLOCKED)),
    }


func migrate_save(document: Dictionary, from_version: int) -> Dictionary:
    if from_version == CURRENT_SAVE_VERSION:
        return _result(true, "OK", "Save already uses the current version", str(document.get("slot_id", "")), {"data": document.duplicate(true)})
    return _result(false, SAVE_VERSION_UNSUPPORTED, "No development migration is available for save version %d" % from_version, str(document.get("slot_id", "")))


func set_playtime_seconds(value: float) -> bool:
    if not _initialized or value < 0.0 or is_nan(value) or is_inf(value):
        return false
    _playtime_seconds = value
    return true


func get_playtime_seconds() -> float:
    return _playtime_seconds


func set_random_state(value: Dictionary) -> bool:
    if not _initialized or not value.has("seed") or not _is_integer_value(value["seed"]):
        return false
    _random_state = value.duplicate(true)
    _random_state["seed"] = int(_random_state["seed"])
    return true


func get_random_state() -> Dictionary:
    return _random_state.duplicate(true)


func get_save_root() -> String:
    return _save_root


func get_backup_root() -> String:
    return _backup_root


func get_save_path(slot_id: String) -> String:
    return _save_root.path_join("%s.json" % slot_id)


func get_backup_path(slot_id: String) -> String:
    return _backup_root.path_join("%s.json.bak" % slot_id)


func _validate_document(document: Dictionary, expected_slot: String, include_prepared_runtime: bool = false) -> Dictionary:
    if document.has("save_version"):
        var raw_save_version: Variant = document["save_version"]
        if not _is_integer_value(raw_save_version) or int(raw_save_version) != CURRENT_SAVE_VERSION:
            return _result(false, SAVE_VERSION_UNSUPPORTED, "Save version is not supported", expected_slot)
    if document.has("game_state") and not document["game_state"] is Dictionary:
        return _result(false, SAVE_STATE_INVALID, "Save snapshot must be an object", expected_slot)
    if document.has("inventory_state") and not document["inventory_state"] is Dictionary:
        return _result(false, SAVE_INVENTORY_INVALID, "Inventory snapshot must be an object", expected_slot)
    var schema_errors: Array[String] = _schema_validator.validate(document, _schema)
    if not schema_errors.is_empty():
        return _result(false, SAVE_SCHEMA_INVALID, schema_errors[0], expected_slot, {"details": schema_errors})
    var save_version := int(document.get("save_version", -1))
    if save_version != CURRENT_SAVE_VERSION:
        return _result(false, SAVE_VERSION_UNSUPPORTED, "Save version %d is not supported" % save_version, expected_slot)
    if not expected_slot.is_empty() and str(document.get("slot_id", "")) != expected_slot:
        return _result(false, SAVE_SCHEMA_INVALID, "Save slot ID does not match its file", expected_slot)

    var preflight := _preflight_restore(document, expected_slot)
    if not bool(preflight.get("ok", false)):
        return preflight
    var result := _result(true, "OK", "Save document is valid", expected_slot)
    if include_prepared_runtime:
        result["prepared_runtime"] = preflight["prepared_runtime"]
    return result


func _preflight_restore(document: Dictionary, slot_id: String) -> Dictionary:
    var snapshot: Variant = document.get("game_state")
    if not snapshot is Dictionary:
        return _result(false, SAVE_STATE_INVALID, "Save snapshot must be an object", slot_id)
    var shadow_state := GameStateClass.new()
    if not shadow_state.initialize_from_content_loader(_content_loader):
        return _result(false, SAVE_STATE_INVALID, "State registry could not initialize for save validation", slot_id, {"details": shadow_state.last_error})
    if not shadow_state.restore_snapshot(snapshot, "save_restore"):
        return _result(false, SAVE_STATE_INVALID, "GameState rejected the save snapshot", slot_id, {"details": shadow_state.last_error})

    var shadow_inventory: Variant = null
    if _inventory_manager != null:
        var inventory_snapshot: Variant = document.get("inventory_state")
        if not inventory_snapshot is Dictionary:
            return _result(false, SAVE_INVENTORY_INVALID, "Save does not contain an InventoryManager snapshot", slot_id)
        shadow_inventory = InventoryManagerClass.new()
        var configured_capacity := int(_inventory_manager.call("get_capacity"))
        if not shadow_inventory.initialize(_content_loader, shadow_state, configured_capacity):
            return _result(false, SAVE_INVENTORY_INVALID, "InventoryManager could not initialize for save validation", slot_id, {
                "details": shadow_inventory.last_error,
            })
        if not shadow_inventory.validate_snapshot(inventory_snapshot):
            return _result(false, SAVE_INVENTORY_INVALID, "InventoryManager snapshot failed validation", slot_id, {
                "details": shadow_inventory.last_error,
            })
        if not shadow_inventory.restore_snapshot(inventory_snapshot, "save_restore"):
            return _result(false, SAVE_INVENTORY_INVALID, "InventoryManager rejected the save snapshot", slot_id, {
                "details": shadow_inventory.last_error,
            })
    elif document.has("inventory_state"):
        return _result(false, SAVE_INVENTORY_INVALID, "Save contains inventory data but no InventoryManager is bound", slot_id)

    var shadow_story := StoryRunnerClass.new()
    if not shadow_story.initialize(_content_loader, shadow_state):
        return _result(false, SAVE_STORY_INVALID, "StoryRunner could not initialize for save validation", slot_id, {"details": shadow_story.last_error})
    var story_id := str(document.get("current_story_id", ""))
    var node_id := str(document.get("current_story_node_id", ""))
    if not shadow_story.restore_position(story_id, node_id, false):
        return _result(false, SAVE_STORY_INVALID, "Saved story position cannot be restored", slot_id, {"details": shadow_story.last_error})
    var prepared_runtime := {
        "game_state": shadow_state.create_runtime_checkpoint(),
        "story_runner": shadow_story.create_runtime_checkpoint(),
    }
    if shadow_inventory != null:
        prepared_runtime["inventory_manager"] = shadow_inventory.create_runtime_checkpoint()
    return _result(true, "OK", "Runtime restore preflight passed", slot_id, {
        "prepared_runtime": prepared_runtime,
    })


func _apply_document(document: Dictionary, slot_id: String, prepared_runtime: Dictionary) -> Dictionary:
    var previous_state: Dictionary = _game_state.call("create_runtime_checkpoint")
    var previous_inventory: Dictionary = {}
    if _inventory_manager != null:
        previous_inventory = _inventory_manager.call("create_runtime_checkpoint")
    var previous_story: Dictionary = _story_runner.call("create_runtime_checkpoint")
    if not bool(_game_state.call("restore_runtime_checkpoint", prepared_runtime["game_state"])):
        var state_failure: Variant = _game_state.get("last_error")
        return _result(false, SAVE_RESTORE_FAILED, "GameState could not commit the prepared save snapshot", slot_id, {
            "details": state_failure,
            "rollback_ok": _rollback_runtime(previous_state, previous_inventory, previous_story),
        })
    if _inventory_manager != null:
        if not prepared_runtime.has("inventory_manager") or not bool(_inventory_manager.call(
            "restore_runtime_checkpoint", prepared_runtime["inventory_manager"]
        )):
            var inventory_failure: Variant = _inventory_manager.get("last_error")
            return _result(false, SAVE_RESTORE_FAILED, "InventoryManager could not commit the prepared save snapshot", slot_id, {
                "details": inventory_failure,
                "rollback_ok": _rollback_runtime(previous_state, previous_inventory, previous_story),
            })
    if not bool(_story_runner.call("restore_runtime_checkpoint", prepared_runtime["story_runner"])):
        var story_failure: Variant = _story_runner.get("last_error")
        return _result(false, SAVE_RESTORE_FAILED, "StoryRunner could not commit the prepared save position", slot_id, {
            "details": story_failure,
            "rollback_ok": _rollback_runtime(previous_state, previous_inventory, previous_story),
        })

    _playtime_seconds = float(document["playtime_seconds"])
    _random_state = document["random_state"].duplicate(true)
    _random_state["seed"] = int(_random_state["seed"])
    _game_state.call("emit_changes_from_checkpoint", previous_state, "save_restore")
    if _inventory_manager != null:
        _inventory_manager.call("emit_changes_from_checkpoint", previous_inventory, "save_restore")
    _story_runner.call("emit_position_restored")
    return _result(true, "OK", "Save loaded", slot_id)


func _rollback_runtime(previous_state: Dictionary, previous_inventory: Dictionary, previous_story: Dictionary) -> bool:
    var story_ok := bool(_story_runner.call("restore_runtime_checkpoint", previous_story))
    var inventory_ok := true
    if _inventory_manager != null:
        inventory_ok = bool(_inventory_manager.call("restore_runtime_checkpoint", previous_inventory))
    var state_ok := bool(_game_state.call("restore_runtime_checkpoint", previous_state))
    return state_ok and inventory_ok and story_ok


func _write_document_atomic(document: Dictionary, slot_id: String, create_backup: bool) -> Dictionary:
    if not _ensure_directories():
        return _result(false, SAVE_WRITE_FAILED, "Save directories are unavailable", slot_id)
    var temp_path := _temp_path(slot_id)
    if FileAccess.file_exists(temp_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
    var text := JSON.stringify(document, "  ", false)
    if not _write_text_file(temp_path, text):
        return _result(false, SAVE_WRITE_FAILED, "Temporary save file could not be written", slot_id)
    var temp_read := _read_json_file(temp_path, slot_id)
    if not bool(temp_read.get("ok", false)) or not bool(_validate_document(temp_read.get("data", {}), slot_id).get("ok", false)):
        _remove_file_if_present(temp_path)
        return _result(false, SAVE_WRITE_FAILED, "Temporary save file failed validation", slot_id)

    var main_path := get_save_path(slot_id)
    if create_backup and FileAccess.file_exists(main_path):
        var backup_result := _backup_existing_save(slot_id)
        if not bool(backup_result.get("ok", false)):
            _remove_file_if_present(temp_path)
            return backup_result
    if not _replace_file(temp_path, main_path):
        _remove_file_if_present(temp_path)
        return _result(false, SAVE_WRITE_FAILED, "Validated temporary save could not replace the main save", slot_id)
    return _result(true, "OK", "Save written", slot_id)


func _backup_existing_save(slot_id: String) -> Dictionary:
    var main_path := get_save_path(slot_id)
    var existing := _read_json_file(main_path, slot_id)
    if not bool(existing.get("ok", false)):
        return _result(true, "OK", "Invalid old main save was not copied over the last good backup", slot_id)
    var validation := _validate_document(existing["data"], slot_id)
    if not bool(validation.get("ok", false)):
        return _result(true, "OK", "Invalid old main save was not copied over the last good backup", slot_id)

    var backup_temp := _backup_temp_path(slot_id)
    if FileAccess.file_exists(backup_temp):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_temp))
    if not _write_text_file(backup_temp, FileAccess.get_file_as_string(main_path)):
        return _result(false, SAVE_WRITE_FAILED, "Backup temporary file could not be written", slot_id)
    var backup_read := _read_json_file(backup_temp, slot_id)
    if not bool(backup_read.get("ok", false)) or not bool(_validate_document(backup_read.get("data", {}), slot_id).get("ok", false)):
        _remove_file_if_present(backup_temp)
        return _result(false, SAVE_WRITE_FAILED, "Backup temporary file failed validation", slot_id)
    if not _replace_file(backup_temp, get_backup_path(slot_id)):
        _remove_file_if_present(backup_temp)
        return _result(false, SAVE_WRITE_FAILED, "Backup could not replace the previous backup", slot_id)
    return _result(true, "OK", "Backup created", slot_id)


func _replace_file(source_path: String, target_path: String) -> bool:
    var source_absolute := ProjectSettings.globalize_path(source_path)
    var target_absolute := ProjectSettings.globalize_path(target_path)
    return DirAccess.rename_absolute(source_absolute, target_absolute) == OK


func _read_json_file(path: String, slot_id: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return _result(false, SAVE_NOT_FOUND, "Save file does not exist", slot_id)
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return _result(false, SAVE_RESTORE_FAILED, "Save file exists but could not be opened", slot_id, {
            "file_error": FileAccess.get_open_error(),
        })
    var text := file.get_as_text()
    file.close()
    var parser := JSON.new()
    var parse_result := parser.parse(text)
    if parse_result != OK:
        return _result(false, SAVE_JSON_INVALID, "Save JSON is invalid at line %d: %s" % [parser.get_error_line(), parser.get_error_message()], slot_id)
    if not parser.data is Dictionary:
        return _result(false, SAVE_SCHEMA_INVALID, "Save JSON root must be an object", slot_id)
    return _result(true, "OK", "Save JSON parsed", slot_id, {"data": parser.data})


func _write_text_file(path: String, text: String) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(text)
    file.flush()
    var write_error := file.get_error()
    file.close()
    return write_error == OK


func _load_schema() -> bool:
    var file := FileAccess.open("res://schemas/save.schema.json", FileAccess.READ)
    if file == null:
        _set_last_result(_result(false, SAVE_SCHEMA_INVALID, "Save schema could not be opened"))
        return false
    var text := file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(text)
    if not parsed is Dictionary:
        _set_last_result(_result(false, SAVE_SCHEMA_INVALID, "Save schema is invalid JSON"))
        return false
    _schema = parsed
    return true


func _ensure_directories() -> bool:
    for path: String in [_save_root, _backup_root]:
        var absolute := ProjectSettings.globalize_path(path)
        if not DirAccess.dir_exists_absolute(absolute) and DirAccess.make_dir_recursive_absolute(absolute) != OK:
            return false
    return true


func _normalize_root(path: String) -> String:
    var normalized := path.strip_edges().replace("\\", "/")
    while normalized.ends_with("/") and not normalized.ends_with("://") and not _is_windows_drive_root(normalized):
        normalized = normalized.trim_suffix("/")
    return normalized


func _is_windows_drive_root(path: String) -> bool:
    return path.length() == 3 and path.substr(1, 2) == ":/"


func _is_allowed_storage_root(path: String) -> bool:
    if path.is_empty() or path.begins_with("res://"):
        return false
    if path.begins_with("user://"):
        var user_absolute := ProjectSettings.globalize_path("user://").simplify_path().replace("\\", "/").trim_suffix("/").to_lower()
        var path_absolute := ProjectSettings.globalize_path(path).simplify_path().replace("\\", "/").to_lower()
        return path_absolute == user_absolute or path_absolute.begins_with("%s/" % user_absolute)
    if not path.is_absolute_path():
        return false
    return not _is_install_path(path)


func _is_install_path(path: String) -> bool:
    var absolute := ProjectSettings.globalize_path(path).simplify_path().replace("\\", "/").to_lower()
    var install_root := ProjectSettings.globalize_path("res://").simplify_path().replace("\\", "/").trim_suffix("/").to_lower()
    return absolute == install_root or absolute.begins_with("%s/" % install_root)


func _validate_slot(slot_id: String) -> Dictionary:
    if slot_id not in SLOT_IDS:
        return _result(false, SAVE_SCHEMA_INVALID, "Unknown save slot '%s'" % slot_id, slot_id)
    return {}


func _runtime_block_result(operation: String, slot_id: String) -> Dictionary:
    var policy := get_persistence_policy(operation)
    if bool(policy.get("allowed", false)):
        return {}
    return _result(
        false,
        SAVE_RUNTIME_BLOCKED,
        str(policy.get("message", "Runtime state does not allow persistence")),
        slot_id,
        {
            "operation": operation,
            "guard_code": str(policy.get("guard_code", SAVE_RUNTIME_BLOCKED)),
        },
    )


func _metadata_from_document(document: Dictionary, valid: bool) -> Dictionary:
    return {
        "slot_id": str(document["slot_id"]),
        "valid": valid,
        "save_version": int(document["save_version"]),
        "game_version": str(document["game_version"]),
        "created_at": str(document["created_at"]),
        "updated_at": str(document["updated_at"]),
        "playtime_seconds": float(document["playtime_seconds"]),
        "current_story_id": str(document["current_story_id"]),
        "current_story_node_id": str(document["current_story_node_id"]),
        "backup_available": FileAccess.file_exists(get_backup_path(str(document["slot_id"]))),
    }


func _temp_path(slot_id: String) -> String:
    return "%s.tmp" % get_save_path(slot_id)


func _backup_temp_path(slot_id: String) -> String:
    return "%s.tmp" % get_backup_path(slot_id)


func _remove_file_if_present(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _now_timestamp() -> String:
    if _clock_provider.is_valid():
        return str(_clock_provider.call())
    return Time.get_datetime_string_from_system(true, false)


func _is_integer_value(value: Variant) -> bool:
    return value is int or (value is float and value == floor(value))


func _result(ok: bool, code: String, message: String, slot_id: String = "", extra: Dictionary = {}) -> Dictionary:
    var result := {"ok": ok, "code": code, "message": message, "slot_id": slot_id}
    result.merge(extra, true)
    return result


func _not_initialized_result(slot_id: String = "") -> Dictionary:
    return _result(false, SAVE_NOT_INITIALIZED, "SaveManager has not been initialized", slot_id)


func _set_last_result(result: Dictionary) -> Dictionary:
    last_result = result.duplicate(true)
    if not bool(result.get("ok", false)):
        printerr("SAVE_ERROR:%s:%s:%s" % [result.get("code", "UNKNOWN"), result.get("slot_id", ""), result.get("message", "")])
    return result


func _emit_save_result(result: Dictionary) -> Dictionary:
    _set_last_result(result)
    save_completed.emit(result.duplicate(true))
    return result


func _emit_load_result(result: Dictionary) -> Dictionary:
    var slot_id := str(result.get("slot_id", ""))
    if not bool(result.get("ok", false)) and slot_id in SLOT_IDS:
        result["backup_available"] = FileAccess.file_exists(get_backup_path(slot_id))
    _set_last_result(result)
    load_completed.emit(result.duplicate(true))
    return result
