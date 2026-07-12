# PUSH 32 — World Atmosphere: Particles, Ambient Details, Audio Design
# Commit: "Push 32: Ambient particles, wind system, audio design, world details"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/world/ambient_wind.gd
# LOCATION: res://scripts/world/ambient_wind.gd
# Attach to: Node2D "AmbientWind" in every outdoor level
# Creates background dust particles that drift across the screen
# ════════════════════════════════════════════════════════════════

extends Node2D

# Spawns tiny dust motes that drift left to right across the level.
# Very subtle — player should barely notice them consciously.
# But their absence in the USSR level will feel strange and right.

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


# ════════════════════════════════════════════════════════════════
# AUDIO DESIGN DOCUMENT
# res://assets/audio/ — what to create and where
# (No code — just the design plan for when you add audio)
# ════════════════════════════════════════════════════════════════

# ADD AS COMMENT BLOCK — read this when implementing audio:
#
# ── MUSIC TRACKS ──────────────────────────────────────────────
#
# track_hometown.ogg
#   Instrument: Dutar (Uzbek two-string lute) + light percussion
#   Mood: Melancholic but warm. Home. Something missing.
#   Loop: YES
#   Use in: Hometown.tscn
#   Alternative if no composer: search "Central Asian folk ambient"
#   on freesound.org (Creative Commons license)
#
# track_muynak.ogg
#   Instrument: SILENCE + distant wind drones
#   Mood: Desolation. The absence of music IS the music here.
#   Loop: YES
#   Actual content: very low frequency wind hum, occasional creak
#   Use in: Muynak.tscn
#
# track_seafloor.ogg
#   Instrument: Sparse piano, single notes, long reverb
#   Mood: Something vast and empty. Underwater memory.
#   Loop: YES
#   Use in: Seafloor.tscn
#
# track_well.ogg
#   Instrument: Single sustained choir note (one voice, no words)
#   Triggered only during magic well activation sequence
#   Duration: 45 seconds, no loop
#
# track_ussr.ogg
#   Instrument: Distant typewriter rhythm + muted strings
#   Mood: Bureaucratic dread. Time passing. Urgency.
#   Loop: YES
#   Use in: USSR.tscn
#
# track_ending_good.ogg
#   Instrument: Full Dutar + piano + gentle percussion
#   Mood: Relief. Pride. Sorrow for what was lost + hope for what returns.
#   Duration: 3 minutes (covers full ending sequence)
#
# ── SOUND EFFECTS ─────────────────────────────────────────────
#
# sfx_footstep_sand.ogg     soft crunch, 4 variants, randomize
# sfx_footstep_salt.ogg     brittle crunch, slightly louder
# sfx_footstep_wood.ogg     hollow thud (ruins buildings)
# sfx_footstep_corridor.ogg hard echo (USSR building)
# sfx_bolgarka.ogg          grinding metal, 0.8s loop while active
# sfx_bolgarka_hit.ogg      spark burst on impact
# sfx_shovel_dig.ogg        dirt scoop, 2 variants
# sfx_spray.ogg             aerosol hiss, 1.2 seconds
# sfx_dialogue_open.ogg     soft paper rustle (dialogue box opens)
# sfx_dialogue_blip.ogg     typewriter tick per character (typewriter effect)
# sfx_item_pickup.ogg       small chime, warm tone
# sfx_damage_player.ogg     sharp inhale + grunt
# sfx_enemy_hit.ogg         dull thud
# sfx_enemy_death_dust.ogg  crumble + puff
# sfx_dust_storm_warning.ogg rising wind, 3 seconds
# sfx_dust_storm_loop.ogg   heavy wind loop
# sfx_well_activate.ogg     deep resonant hum building
# sfx_well_water.ogg        water rushing upward
# sfx_tnt_place.ogg         heavy clunk
# sfx_explosion.ogg         deep boom + rumble
# sfx_water_rise.ogg        gentle rushing water, builds over 8 seconds
# sfx_gate_open.ogg         resonant whoosh, warm harmonic
# sfx_zorin_pen.ogg         pen on paper, deliberate, slow
#
# ── AUDIO BUS SETUP IN GODOT ──────────────────────────────────
# AudioServer panel (bottom of Godot editor):
#   Bus 0: Master
#   Bus 1: Music    (connect to Master, add LowPassFilter for muffling)
#   Bus 2: SFX      (connect to Master)
#   Bus 3: Ambient  (connect to Master, lower volume 0.7)
#   Bus 4: UI       (connect to Master)
#
# ── HOW TO ADD FOOTSTEP SOUNDS ────────────────────────────────
# In player.gd _animate(), when walk animation plays:
#   if anim.frame == 1 or anim.frame == 3:  (footfall frames)
#     var step_sound := AudioStreamPlayer.new()
#     step_sound.stream = preload("res://assets/audio/sfx/sfx_footstep_sand.ogg")
#     step_sound.bus = "SFX"
#     step_sound.volume_db = -8.0
#     add_child(step_sound)
#     step_sound.play()
#     step_sound.finished.connect(step_sound.queue_free)
#
# Change stream based on current tile type for best feel.


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/world/prop_interact.gd
# LOCATION: res://scripts/world/prop_interact.gd
# Reusable script for any world prop that just shows dialogue
# Attach to ANY StaticBody2D prop that needs an interaction line
# Set the lines in Inspector — no unique script per prop needed
# ════════════════════════════════════════════════════════════════

extends StaticBody2D

@export var interaction_lines : Array[String] = [
	"[An old object. Nothing more to see here.]"
]
@export var speaker : String = ""   # leave empty for narrator lines


func interact() -> void:
	var dialogue := []
	for line in interaction_lines:
		dialogue.append({ "speaker": speaker, "text": line })
	DialogueManager.start(dialogue)

# HOW TO USE:
# Add prop_interact.gd to any Sprite2D or StaticBody2D
# In Inspector set interaction_lines array:
#   Element 0: "[The rusted pipe is bone dry. Has been for decades.]"
#   Element 1: "[There is a Soviet stamp on the side. Long faded.]"
# That is all. No other code needed.
# The player's InteractRay will call interact() automatically.
