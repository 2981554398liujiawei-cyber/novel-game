extends Node

const MUSIC := {
    "BGM_VILLAGE_DAY": "res://assets/audio/music/village_loop.ogg",
    "BGM_WILDS": "res://assets/audio/music/wild_loop.ogg",
    "BGM_BOSS": "res://assets/audio/music/boss_loop.ogg",
}
const SFX := {
    "SFX_UI_CONFIRM": "res://assets/audio/sfx/ui_confirm.wav",
    "SFX_UI_CANCEL": "res://assets/audio/sfx/ui_cancel.wav",
    "SFX_UI_SELECT": "res://assets/audio/sfx/ui_click.wav",
    "SFX_COMBAT_HIT": "res://assets/audio/sfx/hit_light.wav",
    "SFX_COMBAT_GUARD": "res://assets/audio/sfx/guard.wav",
    "SFX_COMBAT_SKILL": "res://assets/audio/sfx/hit_heavy.wav",
    "SFX_COMBAT_ITEM": "res://assets/audio/sfx/reward.wav",
    "SFX_COMBAT_RETREAT": "res://assets/audio/sfx/warning.wav",
}

var _music_player := AudioStreamPlayer.new()
var _sfx_player := AudioStreamPlayer.new()
var _master_volume := 1.0
var _music_volume := 0.8
var _sfx_volume := 0.8
var _current_music_id := ""


func _ready() -> void:
    _music_player.name = "MusicPlayer"
    _sfx_player.name = "SfxPlayer"
    add_child(_music_player)
    add_child(_sfx_player)
    _music_player.finished.connect(_music_player.play)
    _apply_volumes()


func set_volumes(master: float, music: float, sfx: float) -> void:
    _master_volume = clampf(master, 0.0, 1.0)
    _music_volume = clampf(music, 0.0, 1.0)
    _sfx_volume = clampf(sfx, 0.0, 1.0)
    _apply_volumes()


func play_music(music_id: String) -> Dictionary:
    if not MUSIC.has(music_id) or not ResourceLoader.exists(str(MUSIC[music_id])):
        return {"ok": false, "code": "AUDIO_MUSIC_MISSING", "music_id": music_id}
    _current_music_id = music_id
    _music_player.stream = load(str(MUSIC[music_id])) as AudioStream
    _music_player.play()
    return {"ok": true, "code": "OK", "music_id": music_id}


func play_sfx(sfx_id: String) -> Dictionary:
    if not SFX.has(sfx_id) or not ResourceLoader.exists(str(SFX[sfx_id])):
        return {"ok": false, "code": "AUDIO_SFX_MISSING", "sfx_id": sfx_id}
    _sfx_player.stream = load(str(SFX[sfx_id])) as AudioStream
    _sfx_player.play()
    return {"ok": true, "code": "OK", "sfx_id": sfx_id}


func get_current_music_id() -> String:
    return _current_music_id


func _apply_volumes() -> void:
    _music_player.volume_db = linear_to_db(maxf(_master_volume * _music_volume, 0.0001))
    _sfx_player.volume_db = linear_to_db(maxf(_master_volume * _sfx_volume, 0.0001))
