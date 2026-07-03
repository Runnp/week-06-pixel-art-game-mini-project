# PUSH 05 — Player in Hometown + Level Door Trigger
# File: res://scripts/systems/level_door.gd
# Commit: "Push 05: Player placed in Hometown, camera working, door trigger"
# Attach to: Area2D node named "LevelDoor" placed at room exit

extends Area2D

@export var target_scene : String = "res://scenes/levels/Muynak.tscn"
@export var door_label   : String = "Travel to Muynak?"

var _player_inside : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_inside and Input.is_action_just_pressed("ui_accept"):
		GameManager.change_scene(target_scene)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		print("[Door] Press E/Space to enter: ", door_label)
		# In Push 07 the HUD will show a proper prompt instead of print


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false


# ── SCENE STRUCTURE FOR LevelDoor ────────────────────────
# Area2D  (name: LevelDoor)
# ├── CollisionShape2D
# │     Shape: RectangleShape2D  size: 32x32
# └── (attach this script)
#
# Place one LevelDoor at the edge of Hometown.tscn
# Set target_scene in Inspector to the next chapter scene path
