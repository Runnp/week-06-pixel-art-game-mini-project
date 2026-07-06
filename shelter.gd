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
