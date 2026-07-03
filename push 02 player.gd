# PUSH 02 — Player Movement
# File: res://scripts/player/player.gd
# Commit: "Push 02: Player movement, 4-direction animation, interact ray"
# Attach to: CharacterBody2D root of Player.tscn

extends CharacterBody2D

# ── Constants ─────────────────────────────────────────────
const SPEED      := 80.0
const MAX_HEALTH := 100

# ── Node refs ─────────────────────────────────────────────
@onready var anim         : AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_ray : RayCast2D        = $InteractRay

# ── State ─────────────────────────────────────────────────
var health   : int    = MAX_HEALTH
var last_dir : String = "down"
var can_move : bool   = true


func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	var input := _get_input()
	velocity   = input * SPEED
	move_and_slide()
	_animate(input)
	_face_ray(input)

	if Input.is_action_just_pressed("ui_accept"):
		_try_interact()


func _get_input() -> Vector2:
	return Vector2(
		Input.get_axis("ui_left",  "ui_right"),
		Input.get_axis("ui_up",    "ui_down")
	).normalized()


func _animate(input: Vector2) -> void:
	if input == Vector2.ZERO:
		anim.play("idle_" + last_dir)
		return

	if abs(input.x) >= abs(input.y):
		anim.play("walk_side")
		anim.flip_h = input.x < 0
		last_dir    = "side"
	elif input.y < 0:
		anim.play("walk_up")
		anim.flip_h = false
		last_dir    = "up"
	else:
		anim.play("walk_down")
		anim.flip_h = false
		last_dir    = "down"


func _face_ray(input: Vector2) -> void:
	if input != Vector2.ZERO:
		interact_ray.target_position = input.normalized() * 24.0


func _try_interact() -> void:
	if interact_ray.is_colliding():
		var target = interact_ray.get_collider()
		if target.has_method("interact"):
			target.interact()


func take_damage(amount: int) -> void:
	health -= amount
	health  = clamp(health, 0, MAX_HEALTH)
	GameManager.emit_signal("player_health_changed", health)
	if health <= 0:
		_die()


func _die() -> void:
	can_move = false
	anim.play("death")
	await anim.animation_finished
	GameManager.emit_signal("player_died")


# ── SCENE STRUCTURE FOR Player.tscn ──────────────────────
# CharacterBody2D  (name: Player, group: "player")
# ├── AnimatedSprite2D
# │     Animations needed:
# │       walk_down  4 frames 8fps loop
# │       walk_up    4 frames 8fps loop
# │       walk_side  4 frames 8fps loop
# │       idle_down  1 frame  1fps loop
# │       idle_up    1 frame  1fps loop
# │       idle_side  1 frame  1fps loop
# │       death      4 frames 6fps no loop
# ├── CollisionShape2D
# │     Shape: CapsuleShape2D  height:20  radius:7
# ├── RayCast2D  (name: InteractRay)
# │     Target: (0, 24)  enabled: ON
# └── Camera2D
#       Position Smoothing: ON  Speed: 5.0
