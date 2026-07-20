
extends CanvasLayer

@onready var label : Label = $PromptLabel

const PROMPT_RANGE  : float = 48.0
const PROMPT_OFFSET : Vector2 = Vector2(0, -28)

var _current_target : Node2D = null
var _player         : Node2D = null

# What text to show per interactable type
const PROMPT_TEXTS := {
	"npc":          "[E] Talk",
	"pickup":       "[E] Pick up",
	"door":         "[E] Enter",
	"soil_patch":   "[E] Treat Soil",
	"tree_spot":    "[E] Plant Tree",
	"ship_wreck":   "[E] Scrap",
	"magic_well":   "[E] Examine Well",
	"aquarium":     "[E] Check Aquarium",
	"shelter_door": "[E] Rest",
	"evidence":     "[E] Take",
	"prop":         "[E] Examine",
	"time_gate":    "[E] Step Through",
}


func _ready() -> void:
	layer         = 6
	label.visible = false
	_player       = get_parent()


func _process(_delta: float) -> void:
	if _player == null:
		return

	var best_target   : Node2D = null
	var best_dist     : float  = PROMPT_RANGE + 1.0
	var interactables := get_tree().get_nodes_in_group("interactable")

	for node in interactables:
		if node is Node2D:
			var dist := _player.global_position.distance_to(
				node.global_position
			)
			if dist < PROMPT_RANGE and dist < best_dist:
				best_dist   = dist
				best_target = node

	if best_target != _current_target:
		_current_target = best_target
		_update_prompt()


func _update_prompt() -> void:
	if _current_target == null:
		label.visible = false
		return

	var prompt_type := _get_prompt_type(_current_target)
	var text        := PROMPT_TEXTS.get(prompt_type, "[E] Interact")

	# Override with custom prompt if node has one
	if _current_target.has_method("get_prompt_text"):
		text = _current_target.get_prompt_text()

	label.text    = text
	label.visible = true
	_position_label()


func _position_label() -> void:
	if _current_target == null:
		return
	# Convert world position to screen position
	var cam := _player.get_node_or_null("Camera2D")
	if cam == null:
		return
	var screen_pos := _current_target.global_position + PROMPT_OFFSET
	label.global_position = screen_pos


func _get_prompt_type(node: Node) -> String:
	if node.is_in_group("npc"):          return "npc"
	if node.is_in_group("pickup"):       return "pickup"
	if node.is_in_group("door"):         return "door"
	if node.is_in_group("soil_patch"):   return "soil_patch"
	if node.is_in_group("tree_spot"):    return "tree_spot"
	if node.is_in_group("ship_wreck"):   return "ship_wreck"
	if node.is_in_group("magic_well"):   return "magic_well"
	if node.is_in_group("aquarium"):     return "aquarium"
	if node.is_in_group("shelter_door"): return "shelter_door"
	if node.is_in_group("evidence"):     return "evidence"
	if node.is_in_group("time_gate"):    return "time_gate"
	return "prop"
