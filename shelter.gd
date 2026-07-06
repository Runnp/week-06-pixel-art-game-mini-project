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
