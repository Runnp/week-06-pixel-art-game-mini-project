extends Node2D

@export var particle_color  : Color = Color(0.8, 0.7, 0.5, 0.4)
@export var spawn_interval  : float = 0.3
@export var particle_speed  : float = 18.0
@export var spawn_y_range   : float = 200.0   # vertical area to spawn across

@onready var spawn_timer : Timer = $SpawnTimer

var _camera_ref : Camera2D = null


func _ready() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_particle)
	spawn_timer.start()
	# Find camera for spawn position reference
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player:
		_camera_ref = player.get_node_or_null("Camera2D")


func _spawn_particle() -> void:
	var cam_pos := Vector2.ZERO
	if _camera_ref:
		cam_pos = _camera_ref.get_screen_center_position()

	# Spawn off left edge of screen, random height
	var particle      := ColorRect.new()
	particle.size      = Vector2(randi_range(1, 3), 1)
	particle.color     = particle_color
	particle.position  = Vector2(
		cam_pos.x - 180.0,
		cam_pos.y + randf_range(-spawn_y_range * 0.5, spawn_y_range * 0.5)
	)
	get_parent().add_child(particle)

	# Drift right and slightly downward
	var travel  := randf_range(320.0, 420.0)
	var drift_y := randf_range(-5.0, 15.0)
	var dur     := travel / particle_speed

	var tween := particle.create_tween()
	tween.tween_property(particle, "position",
		particle.position + Vector2(travel, drift_y), dur)
	tween.parallel().tween_property(particle, "modulate:a",
		0.0, dur * 0.8).set_delay(dur * 0.2)
	await tween.finished
	particle.queue_free()


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/world/day_cycle.gd
# LOCATION: res://scripts/world/day_cycle.gd
# Attach to: Node2D "DayCycle" in Hometown and Muynak
# Simple visual day/night shift — not a full clock system
# Just 3 phases: DAY, DUSK, NIGHT
# ════════════════════════════════════════════════════════════════

extends Node2D

enum Phase { DAY, DUSK, NIGHT }

# How long each phase lasts in REAL seconds
const PHASE_DURATION := {
	Phase.DAY:  180.0,   # 3 minutes
	Phase.DUSK: 30.0,    # 30 second golden transition
	Phase.NIGHT: 120.0,  # 2 minutes
}

const PHASE_COLORS := {
	Phase.DAY:  Color(1.0, 1.0, 1.0,  0.0),   # no tint (full daylight)
	Phase.DUSK: Color(1.0, 0.65, 0.2, 0.25),  # warm orange wash
	Phase.NIGHT:Color(0.2, 0.2, 0.5,  0.45),  # dark blue overlay
}

var current_phase : Phase = Phase.DAY
var phase_timer   : float = 0.0
var _overlay      : ColorRect


func _ready() -> void:
	# Create a fullscreen color overlay
	var layer       := CanvasLayer.new()
	layer.layer      = 3   # above world, below HUD
	_overlay         = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_overlay.color          = PHASE_COLORS[Phase.DAY]
	layer.add_child(_overlay)
	add_child(layer)


func _process(delta: float) -> void:
	phase_timer += delta
	if phase_timer >= PHASE_DURATION[current_phase]:
		phase_timer = 0.0
		_advance_phase()


func _advance_phase() -> void:
	match current_phase:
		Phase.DAY:   _transition_to(Phase.DUSK)
		Phase.DUSK:  _transition_to(Phase.NIGHT)
		Phase.NIGHT: _transition_to(Phase.DAY)


func _transition_to(new_phase: Phase) -> void:
	current_phase = new_phase
	var target    := PHASE_COLORS[new_phase]
	var duration  := 8.0 if new_phase == Phase.DUSK else 15.0

	var tween := create_tween()
	tween.tween_property(_overlay, "color", target, duration)

	# Notify streetlights (future: they turn ON at night)
	get_tree().call_group("streetlight", "set_night_mode",
		new_phase == Phase.NIGHT)
