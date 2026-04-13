extends Node

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"

const EVENT_TO_BANK_KEY: Dictionary = {
	"combat.weapon_fired": "weapon_fire",
	"combat.reload_started": "reload",
	"combat.hit_confirmed": "hit_confirm",
	"combat.enemy_fire": "enemy_fire",
	"combat.enemy_died": "enemy_die",
	"combat.player_hit": "player_hit",
	"combat.projectile_impact": "projectile_impact",
	"ability_triggered": "ability_activate",
	"boss.telegraph_strike": "boss_telegraph_strike",
	"boss.telegraph_nova": "boss_telegraph_nova",
	"ability.toxic_hazard_spawned": "ability_toxic_loop",
	"ability.toxic_hazard_tick": "ability_toxic_tick",
	"ui.dialogue_advance": "ui_dialogue_next",
	"ui.click": "ui_click",
	"ui.objective_update": "ui_objective_update"
}

var _bank_paths: Dictionary = {
	"weapon_fire": [
		"res://assets/audio/sfx/combat/weapon_fire_01.ogg",
		"res://assets/audio/sfx/combat/weapon_fire_02.ogg"
	],
	"reload": [
		"res://assets/audio/sfx/combat/reload_01.ogg"
	],
	"hit_confirm": [
		"res://assets/audio/sfx/combat/hit_confirm_01.ogg",
		"res://assets/audio/sfx/combat/hit_confirm_02.ogg"
	],
	"enemy_fire": [
		"res://assets/audio/sfx/combat/enemy_fire_01.ogg",
		"res://assets/audio/sfx/combat/enemy_fire_02.ogg"
	],
	"enemy_die": [
		"res://assets/audio/sfx/combat/enemy_die_01.ogg",
		"res://assets/audio/sfx/combat/enemy_die_02.ogg"
	],
	"player_hit": [
		"res://assets/audio/sfx/combat/player_hit_01.ogg"
	],
	"projectile_impact": [
		"res://assets/audio/sfx/combat/projectile_impact_01.ogg"
	],
	"ability_activate": [
		"res://assets/audio/sfx/abilities/ability_activate_01.ogg"
	],
	"ability_toxic_loop": [
		"res://assets/audio/sfx/abilities/toxic_hazard_loop_01.ogg"
	],
	"ability_toxic_tick": [
		"res://assets/audio/sfx/abilities/toxic_hazard_tick_01.ogg"
	],
	"boss_telegraph_strike": [
		"res://assets/audio/sfx/boss/telegraph_strike_01.ogg"
	],
	"boss_telegraph_nova": [
		"res://assets/audio/sfx/boss/telegraph_nova_01.ogg"
	],
	"ui_dialogue_next": [
		"res://assets/audio/sfx/ui/dialogue_next_01.ogg"
	],
	"ui_objective_update": [
		"res://assets/audio/sfx/ui/objective_update_01.ogg"
	],
	"ui_click": [
		"res://assets/audio/sfx/ui/ui_click_01.ogg"
	],
	"footstep_metal": [
		"res://assets/audio/sfx/footsteps/step_metal_01.wav",
		"res://assets/audio/sfx/footsteps/step_metal_02.wav",
		"res://assets/audio/sfx/footsteps/step_metal_03.wav"
	],
	"ambient_warzone": [
		"res://assets/audio/sfx/ambience/warzone_ambient_loop_01.ogg"
	],
	"ambient_machine": [
		"res://assets/audio/sfx/ambience/machine_ambient_loop_01.ogg"
	],
	"music_combat_a": [
		"res://assets/audio/music/combat_hardrock_01.wav"
	],
	"music_combat_b": [
		"res://assets/audio/music/combat_hardrock_02.ogg"
	],
	"music_intermission": [
		"res://assets/audio/music/intermission_rock_ballad_01.ogg"
	]
}

var _banks: Dictionary = {}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _ui_player: AudioStreamPlayer
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _ambient_player_a: AudioStreamPlayer
var _ambient_player_b: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer3D] = []
var _sfx_pool_index: int = 0
var _current_music_key: String = ""
var _footstep_timer: float = 0.0
var _audio_runtime_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_audio_runtime_enabled = DisplayServer.get_name() != "headless"
	if not _audio_runtime_enabled:
		return
	_load_audio_banks()
	_ensure_buses()
	_create_players()
	if EventBus and EventBus.has_signal("gameplay_event_emitted"):
		EventBus.gameplay_event_emitted.connect(_on_gameplay_event)
	if SettingsSystem and SettingsSystem.has_signal("settings_changed"):
		SettingsSystem.settings_changed.connect(_on_settings_changed)
	_apply_settings_audio_levels()
	_play_ambient_layers()

func play_sfx(bank_key: String, payload: Dictionary = {}) -> void:
	if not _audio_runtime_enabled:
		return
	_play_bank_sfx(bank_key, payload)

func play_ui_event(bank_key: String, payload: Dictionary = {}) -> void:
	if not _audio_runtime_enabled:
		return
	var ui_key: String = bank_key
	if not ui_key.begins_with("ui_"):
		ui_key = "ui_%s" % ui_key
	_play_bank_sfx(ui_key, payload)

func on_gameplay_event(event_name: String, payload: Dictionary = {}) -> void:
	if not _audio_runtime_enabled:
		return
	_on_gameplay_event(event_name, payload)

func play_event(event_name: String, payload: Dictionary = {}) -> void:
	if not _audio_runtime_enabled:
		return
	if event_name == "":
		return
	if EVENT_TO_BANK_KEY.has(event_name):
		_play_bank_sfx(str(EVENT_TO_BANK_KEY[event_name]), payload)
		return
	match event_name:
		"audio.play_sfx":
			var cue_sfx: String = str(payload.get("cue", ""))
			if cue_sfx != "":
				_play_bank_sfx(cue_sfx, payload)
		"audio.play_music":
			var cue_music: String = str(payload.get("cue", ""))
			if cue_music.find("intermission") != -1:
				transition_music("music_intermission")
			elif cue_music.find("02") != -1 or cue_music.find("boss") != -1:
				transition_music("music_combat_b")
			else:
				transition_music("music_combat_a")
		"mission.wave_started":
			if int(payload.get("wave", 1)) >= 2:
				transition_music("music_combat_b")
		"music.combat":
			transition_music("music_combat_a")
		"music.boss":
			transition_music("music_combat_b")
		"music.intermission":
			transition_music("music_intermission")
		"footstep.metal":
			_play_bank_sfx("footstep_metal", payload)
		"ability.toxic_loop":
			_play_bank_sfx("ability_toxic_loop", payload)
		"ability.toxic_tick":
			_play_bank_sfx("ability_toxic_tick", payload)
		_:
			pass

func transition_music(bank_key: String) -> void:
	if not _audio_runtime_enabled:
		return
	if bank_key == "" or _current_music_key == bank_key:
		return
	var stream: AudioStream = _pick_stream_from_bank(bank_key)
	if stream == null:
		return
	_current_music_key = bank_key
	if not _music_player_a.playing:
		_music_player_a.stream = stream
		_music_player_a.volume_db = -2.0
		_music_player_a.play()
		_music_player_b.stop()
		return
	_music_player_b.stream = stream
	_music_player_b.volume_db = -80.0
	_music_player_b.play()
	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(_music_player_a, "volume_db", -80.0, 1.3)
	fade_tween.tween_property(_music_player_b, "volume_db", -2.0, 1.3)
	fade_tween.finished.connect(func() -> void:
		_music_player_a.stop()
		var swap: AudioStreamPlayer = _music_player_a
		_music_player_a = _music_player_b
		_music_player_b = swap
	)

func _on_gameplay_event(event_name: String, payload: Dictionary) -> void:
	if event_name == "combat.player_hit":
		var health_ratio: float = 1.0
		if GameState and GameState.MAX_HEALTH > 0.0:
			health_ratio = clampf(GameState.health / GameState.MAX_HEALTH, 0.0, 1.0)
		if health_ratio < 0.28:
			transition_music("music_intermission")
		elif health_ratio < 0.6:
			transition_music("music_combat_b")
	if event_name == "mission.wave_started":
		var wave_number: int = int(payload.get("wave", 1))
		if wave_number >= 3:
			transition_music("music_combat_b")
	if event_name == "mission.optional_started":
		transition_music("music_combat_b")
	if event_name == "mission.optional_completed":
		transition_music("music_combat_a")
	play_event(event_name, payload)

func _on_settings_changed(setting_name: String, value: Variant) -> void:
	if not _audio_runtime_enabled:
		return
	if setting_name.begins_with("master_volume") or setting_name.begins_with("music_volume") or setting_name.begins_with("sfx_volume"):
		_apply_settings_audio_levels()
	if setting_name == "music_combat_variant":
		if str(value) == "heavy":
			transition_music("music_combat_b")
		else:
			transition_music("music_combat_a")

func _physics_process(delta: float) -> void:
	_footstep_timer = maxf(0.0, _footstep_timer - delta)

func _apply_settings_audio_levels() -> void:
	_set_bus_volume(BUS_MASTER, _resolve_volume_db("master"))
	_set_bus_volume(BUS_MUSIC, _resolve_volume_db("music"))
	_set_bus_volume(BUS_SFX, _resolve_volume_db("sfx"))
	_set_bus_volume(BUS_UI, _resolve_volume_db("sfx"))

func _resolve_volume_db(domain: String) -> float:
	var default_linear: float = 1.0
	match domain:
		"music":
			default_linear = 0.8
		"sfx":
			default_linear = 0.9
		_:
			default_linear = 0.9
	var db_setting_name: String = "%s_volume_db" % domain
	if SettingsSystem and SettingsSystem.has_method("get_setting"):
		var db_value: Variant = SettingsSystem.get_setting(db_setting_name, null)
		if db_value != null:
			return float(db_value)
		var linear_name: String = "%s_volume" % domain
		var linear_value: float = float(SettingsSystem.get_setting(linear_name, default_linear))
		return linear_to_db(clampf(linear_value, 0.001, 1.0))
	return linear_to_db(default_linear)

func _ensure_buses() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_UI)

func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var bus_count: int = AudioServer.bus_count
	AudioServer.add_bus(bus_count)
	AudioServer.set_bus_name(bus_count, bus_name)

func _set_bus_volume(bus_name: StringName, db_value: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, db_value)

func _create_players() -> void:
	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = BUS_UI
	add_child(_ui_player)

	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = BUS_MUSIC
	_music_player_a.stream_paused = false
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = BUS_MUSIC
	add_child(_music_player_b)

	_ambient_player_a = AudioStreamPlayer.new()
	_ambient_player_a.bus = BUS_SFX
	add_child(_ambient_player_a)

	_ambient_player_b = AudioStreamPlayer.new()
	_ambient_player_b.bus = BUS_SFX
	add_child(_ambient_player_b)

	for _idx in range(14):
		var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		player.bus = BUS_SFX
		player.max_distance = 48.0
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.unit_size = 8.0
		add_child(player)
		_sfx_pool.append(player)

func _play_ambient_layers() -> void:
	var ambient_a: AudioStream = _pick_stream_from_bank("ambient_warzone")
	var ambient_b: AudioStream = _pick_stream_from_bank("ambient_machine")
	if ambient_a:
		_ambient_player_a.stream = ambient_a
		_ambient_player_a.volume_db = -12.0
		_ambient_player_a.play()
	if ambient_b:
		_ambient_player_b.stream = ambient_b
		_ambient_player_b.volume_db = -16.0
		_ambient_player_b.play()
	transition_music("music_combat_a")

func _play_bank_sfx(bank_key: String, payload: Dictionary = {}) -> void:
	var stream: AudioStream = _pick_stream_from_bank(bank_key)
	if stream == null:
		return
	if bank_key == "footstep_metal":
		if _footstep_timer > 0.0:
			return
		_footstep_timer = 0.2
	var use_ui: bool = bank_key.begins_with("ui_")
	if use_ui:
		_ui_player.stream = stream
		_ui_player.pitch_scale = _resolve_pitch(payload)
		_ui_player.play()
		return
	if _sfx_pool.is_empty():
		return
	var player: AudioStreamPlayer3D = _sfx_pool[_sfx_pool_index % _sfx_pool.size()]
	_sfx_pool_index += 1
	player.stream = stream
	player.pitch_scale = _resolve_pitch(payload)
	player.global_position = _resolve_sfx_position(payload)
	player.play()

func _pick_stream_from_bank(bank_key: String) -> AudioStream:
	if not _banks.has(bank_key):
		return null
	var bank: Array = _banks[bank_key] as Array
	if bank.is_empty():
		return null
	var idx: int = _rng.randi_range(0, bank.size() - 1)
	return bank[idx] as AudioStream

func _load_audio_banks() -> void:
	_banks.clear()
	for bank_key_variant in _bank_paths.keys():
		var bank_key: String = str(bank_key_variant)
		var path_list_variant: Variant = _bank_paths[bank_key]
		if not (path_list_variant is Array):
			continue
		var streams: Array[AudioStream] = []
		for path_variant in path_list_variant as Array:
			var resource_path: String = str(path_variant)
			var stream: AudioStream = load(resource_path) as AudioStream
			if stream != null:
				streams.append(stream)
		_banks[bank_key] = streams

func _resolve_sfx_position(payload: Dictionary) -> Vector3:
	if payload.has("position") and payload["position"] is Vector3:
		return payload["position"] as Vector3
	if get_tree().current_scene and get_tree().current_scene.has_node("Player"):
		var player: Node3D = get_tree().current_scene.get_node_or_null("Player") as Node3D
		if player:
			return player.global_position
	return Vector3.ZERO

func _resolve_pitch(payload: Dictionary) -> float:
	if payload.has("pitch") and payload["pitch"] is float:
		return clampf(float(payload["pitch"]), 0.8, 1.25)
	return _rng.randf_range(0.96, 1.04)
