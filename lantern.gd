extends Node2D

@export var light_range   : float = 80.0
@export var light_energy  : float = 1.2
@export var is_pickup     : bool  = true   # false = world-placed lantern
@export var flicker       : bool  = true

@onready var light : PointLight2D     = $PointLight2D
@onready var anim  : AnimatedSprite2D = $AnimatedSprite2D

var _held     : bool  = false
var _fuel     : float = 120.0   # seconds of fuel when picked up
const FUEL_DRAIN : float = 1.0  # per second when held


func _ready() -> void:
	light.texture_scale = light_range / 100.0
	light.energy        = light_energy
	add_to_group("lantern")

	if is_pickup:
		$PickupArea.body_entered.connect(_on_pickup)
	if flicker:
		_start_flicker()


func _process(delta: float) -> void:
	if not _held:
		return
	_fuel -= FUEL_DRAIN * delta
	if _fuel <= 0:
		_extinguish()
		return

	# Dim as fuel runs low
	if _fuel < 20.0:
		light.energy = light_energy * (_fuel / 20.0)


func _start_flicker() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(light, "energy",
		light_energy * 0.85, randf_range(0.08, 0.15))
	tween.tween_property(light, "energy",
		light_energy, randf_range(0.08, 0.15))


func _on_pickup(body: Node2D) -> void:
	if not body.is_in_group("player") or not is_pickup:
		return
	_held = true
	Inventory.add_item("lantern", 1)
	light.visible = false   # goes into inventory
	anim.visible  = false
	queue_free()


func activate_held() -> void:
	_held         = true
	light.visible = true
	anim.play("burn")


func _extinguish() -> void:
	_held         = false
	light.visible = false
	anim.play("out")
	Inventory.remove_item("lantern")
	DialogueManager.start([
		{ "speaker": "Rustam", "text": "The lantern is out. I need to find another." }
	])
