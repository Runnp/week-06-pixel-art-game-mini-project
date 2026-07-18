# PUSH 46 — Audio Manager
# Commit: "Push 46: AudioManager autoload, music transitions, SFX pool"
# File: res://scripts/systems/audio_manager.gd
# REGISTER AS AUTOLOAD: Name it "AudioManager"
# ═══════════════════════════════════════════════════════════════

extends Node

# ── Music players (crossfade between two) ─────────
var _music_a   : AudioStreamPlayer
var _music_b   : AudioStreamPlayer
var _active_ab : bool = true   # true = A playing, false = B playing

# ── SFX pool — reuses players instead of creating new ones ────
const SFX_POOL_SIZE : int = 12
var _sfx_pool : Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

# ── Preloaded tracks ──────────────────────────────
# These will load when audio files exist — safe to call before files do
const MUSIC_PATHS := {
	"hometown":    "res://assets/audio/music/track_hometown.ogg",
	"muynak":      "res://assets/audio/music/track_muynak.ogg",
	"seafloor":    "res://assets/audio/music/track_seafloor.ogg",
	"border":      "res://assets/audio/music/track_border.ogg",
	"ussr":        "res://assets/audio/music/track_ussr.ogg",
	"well":        "res://assets/audio/music/track_well.ogg",
	"ending_good": "res://assets/audio/music/track_ending_good.ogg",
	"menu":        "res://assets/audio/music/track_menu.ogg",
}

const SFX_PATHS := {
	"footstep_sand":   "res://assets/audio/sfx/sfx_footstep_sand.ogg",
	"footstep_salt":   "res://assets/audio/sfx/sfx_footstep_salt.ogg",
	"footstep_wood":   "res://assets/audio/sfx/sfx_footstep_wood.ogg",
	"bolgarka":        "res://assets/audio/sfx/sfx_bolgarka.ogg",
	"bolgarka_hit":    "res://assets/audio/sfx/sfx_bolgarka_hit.ogg",
	"shovel_dig":      "res://assets/audio/sfx/sfx_shovel_dig.ogg",
	"spray":           "res://assets/audio/sfx/sfx_spray.ogg",
	"item_pickup":     "res://assets/audio/sfx/sfx_item_pickup.ogg",
	"dialogue_open":   "res://assets/audio/sfx/sfx_dialogue_open.ogg",
	"dialogue_blip":   "res://assets/audio/sfx/sfx_dialogue_blip.ogg",
	"damage_player":   "res://assets/audio/sfx/sfx_damage_player.ogg",
	"enemy_hit":       "res://assets/audio/sfx/sfx_enemy_hit.ogg",
	"enemy_death":     "res://assets/audio/sfx/sfx_enemy_death_dust.ogg",
	"storm_warning":   "res://assets/audio/sfx/sfx_dust_storm_warning.ogg",
	"explosion":       "res://assets/audio/sfx/sfx_explosion.ogg",
	"water_rise":      "res://assets/audio/sfx/sfx_water_rise.ogg",
	"well_activate":   "res://assets/audio/sfx/sfx_well_activate.ogg",
	"gate_open":       "res://assets/audio/sfx/sfx_gate_open.ogg",
	"zorin_pen":       "res://assets/audio/sfx/sfx_zorin_pen.ogg",
}

var _current_track : String = ""


func _ready() -> void:
	# Build music crossfade players
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	_music_a.bus = "Music"
	_music_b.bus = "Music"
	add_child(_music_a)
	add_child(_music_b)

	# Build SFX pool
	for i in SFX_POOL_SIZE:
		var p   := AudioStreamPlayer.new()
		p.bus    = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	# Connect chapter changes to auto-switch music
	GameManager.chapter_changed.connect(_on_chapter_changed)


# ── Play music with crossfade ─────────────────────
func play_music(track_key: String, fade_time: float = 1.5) -> void:
	if track_key == _current_track:
		return
	_current_track = track_key

	var path := MUSIC_PATHS.get(track_key, "")
	if path == "" or not ResourceLoader.exists(path):
		# No file yet — silence gracefully
		_fade_out_current(fade_time)
		return

	var stream := load(path)
	var next   := _music_b if _active_ab else _music_a
	var prev   := _music_a if _active_ab else _music_b

	next.stream    = stream
	next.volume_db = -40.0
	next.play()

	var tween := create_tween()
	tween.tween_property(next, "volume_db",
		linear_to_db(SettingsManager.music_volume), fade_time)
	tween.parallel().tween_property(prev, "volume_db", -40.0, fade_time)
	await tween.finished
	prev.stop()
	_active_ab = not _active_ab


func _fade_out_current(fade_time: float) -> void:
	var current := _music_a if _active_ab else _music_b
	var tween   := create_tween()
	tween.tween_property(current, "volume_db", -40.0, fade_time)
	await tween.finished
	current.stop()


func stop_music(fade_time: float = 1.0) -> void:
	_current_track = ""
	_fade_out_current(fade_time)


# ── Play SFX from pool ────────────────────────────
func play_sfx(sfx_key: String, volume_db: float = 0.0,
			  pitch: float = 1.0) -> void:
	var path := SFX_PATHS.get(sfx_key, "")
	if path == "" or not ResourceLoader.exists(path):
		return   # no file yet — skip silently

	var player         := _sfx_pool[_sfx_index]
	_sfx_index          = (_sfx_index + 1) % SFX_POOL_SIZE
	player.stream       = load(path)
	player.volume_db    = volume_db + linear_to_db(SettingsManager.sfx_volume)
	player.pitch_scale  = pitch + randf_range(-0.05, 0.05)   # slight variation
	player.play()


# ── Play SFX with positional variation ───────────
func play_sfx_at(sfx_key: String, world_pos: Vector2,
				 max_range: float = 200.0) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var dist   := player.global_position.distance_to(world_pos)
	if dist > max_range:
		return
	var vol_db := -20.0 * (dist / max_range)
	play_sfx(sfx_key, vol_db)


# ── Auto-switch music per chapter ─────────────────
func _on_chapter_changed(chapter: int) -> void:
	match chapter:
		1: play_music("hometown")
		2: play_music("muynak")
		3: play_music("seafloor")
		4: play_music("border")
		5: play_music("ussr")


# ── Convenience wrappers ──────────────────────────
func footstep(tile_type: String = "sand") -> void:
	play_sfx("footstep_" + tile_type, -6.0,
		randf_range(0.9, 1.1))

func hit_enemy() -> void:
	play_sfx("enemy_hit", -2.0)

func player_hurt() -> void:
	play_sfx("damage_player", 0.0)

func pickup() -> void:
	play_sfx("item_pickup", -4.0)

func dialogue_blip() -> void:
	play_sfx("dialogue_blip", -10.0,
		randf_range(0.95, 1.05))
