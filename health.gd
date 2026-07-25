extends Area2D

@export var heal_amount  : int    = 30
@export var item_label   : String = "Water Ration"
@export var bob_height   : float  = 4.0   # gentle floating bob
@export var bob_speed    : float  = 2.0

@onready var sprite : Sprite2D = $Sprite2D

var _bob_offset : float = 0.0
var _origin_y   : float = 0.0


func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	_origin_y   = position.y
	# Randomize bob phase so items don't all bob in sync
	_bob_offset = randf() * TAU


func _process(delta: float) -> void:
	# Gentle floating bob animation
	_bob_offset    += delta * bob_speed
	position.y      = _origin_y + sin(_bob_offset) * bob_height


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	var healed := mini(heal_amount, body.MAX_HEALTH - body.health)
	body.health = min(body.health + heal_amount, body.MAX_HEALTH)
	GameManager.emit_signal("player_health_changed", body.health)

	if AudioManager:
		AudioManager.pickup()

	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_prompt("+%d  %s" % [healed, item_label])
		await get_tree().create_timer(1.5).timeout
		hud.hide_prompt()

	# Tiny pop effect before removing
	var tween := create_tween()
	tween.tween_property(sprite, "scale",
		Vector2(1.6, 1.6), 0.08)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()
