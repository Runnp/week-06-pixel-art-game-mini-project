extends Node

signal weather_changed(type: String, intensity: float)

enum WeatherType { CLEAR, WINDY, DUSTY, SANDSTORM }

var current_weather   : WeatherType = WeatherType.CLEAR
var wind_intensity    : float       = 0.0   # 0.0 to 1.0
var _weather_timer    : float       = 0.0
var _next_change_at   : float       = 60.0

# Per-level weather probability weights
# Format: { WeatherType: weight }
const LEVEL_WEATHER := {
	"Hometown": {
		WeatherType.CLEAR:     50,
		WeatherType.WINDY:     30,
		WeatherType.DUSTY:     15,
		WeatherType.SANDSTORM: 5,
	},
	"Muynak": {
		WeatherType.CLEAR:     20,
		WeatherType.WINDY:     30,
		WeatherType.DUSTY:     30,
		WeatherType.SANDSTORM: 20,
	},
	"Seafloor": {
		WeatherType.CLEAR:     10,
		WeatherType.WINDY:     25,
		WeatherType.DUSTY:     35,
		WeatherType.SANDSTORM: 30,
	},
	"Border": {
		WeatherType.CLEAR:     30,
		WeatherType.WINDY:     40,
		WeatherType.DUSTY:     20,
		WeatherType.SANDSTORM: 10,
	},
}

var _current_level : String = "Hometown"
var _overlay       : ColorRect = null
var _canvas        : CanvasLayer = null


func _ready() -> void:
	_canvas       = CanvasLayer.new()
	_canvas.layer = 4
	add_child(_canvas)

	_overlay               = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_overlay.color          = Color(0.7, 0.55, 0.3, 0.0)
	_canvas.add_child(_overlay)

	GameManager.chapter_changed.connect(_on_chapter_changed)
	_schedule_next_change()


func _process(delta: float) -> void:
	_weather_timer += delta
	if _weather_timer >= _next_change_at:
		_weather_timer = 0.0
		_roll_weather()
		_schedule_next_change()


func set_level(level_name: String) -> void:
	_current_level = level_name
	_roll_weather()


func _roll_weather() -> void:
	var weights := LEVEL_WEATHER.get(_current_level,
		LEVEL_WEATHER["Hometown"])

	var total  := 0
	for w in weights.values():
		total += w

	var roll   := randi() % total
	var cumul  := 0
	var chosen := WeatherType.CLEAR

	for type in weights:
		cumul += weights[type]
		if roll < cumul:
			chosen = type
			break

	_transition_to(chosen)


func _transition_to(new_type: WeatherType) -> void:
	current_weather = new_type

	match new_type:
		WeatherType.CLEAR:
			wind_intensity = 0.0
			_set_overlay(Color(0, 0, 0, 0), 6.0)
		WeatherType.WINDY:
			wind_intensity = 0.3
			_set_overlay(Color(0.7, 0.6, 0.4, 0.05), 4.0)
		WeatherType.DUSTY:
			wind_intensity = 0.6
			_set_overlay(Color(0.7, 0.55, 0.3, 0.18), 3.0)
			_warn_player("The air thickens with dust.")
		WeatherType.SANDSTORM:
			wind_intensity = 1.0
			_set_overlay(Color(0.65, 0.45, 0.2, 0.45), 2.0)
			_warn_player("⚠ Sandstorm — find shelter!")
			_notify_npcs_seek_shelter()

	emit_signal("weather_changed", WeatherType.keys()[new_type], wind_intensity)


func _set_overlay(target: Color, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color", target, duration)


func _warn_player(msg: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_prompt"):
		hud.show_prompt(msg)
		await get_tree().create_timer(3.0).timeout
		hud.hide_prompt()


func _notify_npcs_seek_shelter() -> void:
	# All NPCs with shelter behavior stop their patrol
	get_tree().call_group("npc", "on_sandstorm_start")


func _schedule_next_change() -> void:
	_next_change_at = randf_range(45.0, 120.0)


func _on_chapter_changed(chapter: int) -> void:
	var names := {1: "Hometown", 2: "Muynak", 3: "Seafloor", 4: "Border"}
	_current_level = names.get(chapter, "Hometown")


func is_storming() -> bool:
	return current_weather == WeatherType.SANDSTORM


func get_wind_speed_modifier() -> float:
	# Enemies move faster in wind, player slightly slower
	return wind_intensity * 0.25


# ── ADD TO npc_base.gd ────────────────────────────
# func on_sandstorm_start() -> void:
#     # NPCs freeze in place during sandstorm
#     var saved_speed := move_speed
#     move_speed = 0.0
#     await WeatherManager.weather_changed
#     move_speed = saved_speed
#
# ── ADD TO player.gd _physics_process ─────────────
# If WeatherManager.is_storming() and not in shelter:
#     velocity *= (1.0 - WeatherManager.wind_intensity * 0.3)
#     (player moves 30% slower in full sandstorm)
#
# ── ADD TO dust_drifter.gd _on_ready_override ─────
# WeatherManager.weather_changed.connect(_on_weather)
# func _on_weather(_type, intensity):
#     chase_speed = 55.0 + (intensity * 30.0)
#     (dust drifters get faster in storms)
