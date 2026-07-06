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
