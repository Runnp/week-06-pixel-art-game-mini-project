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
