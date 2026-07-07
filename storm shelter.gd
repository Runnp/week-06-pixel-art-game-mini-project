# PUSH 16 — Dust Storm + Shelter System
# Commit: "Push 16: Dust storm hazard, shelter areas, storm warning UI"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/world/dust_storm.gd   (already provided)
# FILE 2: res://scripts/world/shelter.gd
# LOCATION: res://scripts/world/shelter.gd
# Attach to: Area2D nodes placed at shelter spots in each level
# ════════════════════════════════════════════════════════════════

extends Area2D

# A shelter is any covered spot that protects Rustam from storms.
# Examples: rusted ship hull, Bibi's house doorway, supply tent.
# Add to group "shelter" so DustStorm can detect it.

@export var shelter_name : String = "Shelter"

var _player_inside : bool = false


func _ready() -> void:
	add_to_group("shelter")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_prompt("Sheltered — safe from storm")


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.hide_prompt()


func is_player_sheltered() -> bool:
	return _player_inside


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/ui/storm_warning.gd
# LOCATION: res://scripts/ui/storm_warning.gd
# Attach to: CanvasLayer node "StormWarning" in HUD.tscn
# Flashes a red warning bar at top of screen when storm incoming
# ════════════════════════════════════════════════════════════════

extends CanvasLayer

@onready var warning_bar   : PanelContainer = $WarningBar
@onready var warning_label : Label          = $WarningBar/Label


func _ready() -> void:
	layer                = 50
	warning_bar.visible  = false
	warning_label.text   = "⚠ DUST STORM INCOMING — FIND SHELTER"


func show_warning() -> void:
	warning_bar.visible = true
	# Blink 3 times
	for i in 3:
		warning_bar.modulate.a = 1.0
		await get_tree().create_timer(0.4).timeout
		warning_bar.modulate.a = 0.3
		await get_tree().create_timer(0.4).timeout
	warning_bar.modulate.a = 1.0


func hide_warning() -> void:
	var tween := create_tween()
	tween.tween_property(warning_bar, "modulate:a", 0.0, 0.5)
	await tween.finished
	warning_bar.visible = false


# ── SCENE STRUCTURE ADDITIONS ─────────────────────────────────
#
# In Hometown.tscn add:
#   Area2D (shelter.gd) → placed over Bibi's doorway
#
# In Muynak.tscn add:
#   Area2D (shelter.gd) → placed inside largest ship hull
#   Node2D (dust_storm.gd) → add DustStorm node to scene
#   ├── Timer (name: StormTimer)
#   └── ColorRect (name: StormOverlay) fullrect color:#99723300
#
# In HUD.tscn add:
#   CanvasLayer (storm_warning.gd)
#   └── PanelContainer (name: WarningBar)
#       └── Label (name: Label)  text: "⚠ DUST STORM INCOMING"
#
# To connect storm → warning UI, edit dust_storm.gd _begin_warning():
#   var warning := get_tree().get_first_node_in_group("storm_warning")
#   if warning: warning.show_warning()
# Add storm_warning to group "storm_warning" in its _ready()
