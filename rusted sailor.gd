# PUSH 12 — Second Enemy: Rusted Sailor
# File: res://scripts/enemies/rusted_sailor.gd
# Commit: "Push 12: Rusted Sailor enemy, ranged shard throw, anchor slam"

extends "res://scripts/enemies/base_enemy.gd"

# Projectile scene — create a simple Area2D with Sprite2D and this script
const SHARD_SCENE := preload("res://scenes/enemies/MetalShard.tscn")

var _throw_range  : float = 80.0   # starts throwing before melee range


func _on_ready_override() -> void:
	max_health      = 40
	move_speed      = 22.0
	chase_speed     = 40.0
	detect_range    = 110.0
	attack_range    = 14.0     # melee slam range
	attack_damage   = 12
	attack_cooldown = 2.0
	health          = max_health


func _update_state() -> void:
	if _player == null or state == State.HURT:
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist <= attack_range:
		state = State.ATTACK          # anchor slam
	elif dist <= _throw_range:
		state = State.ATTACK          # reuse ATTACK state, _attack() checks distance
	elif dist <= detect_range:
		state = State.CHASE
	else:
		state = State.PATROL


func _attack() -> void:
	if _player == null or _atk_timer > 0:
		return

	var dist := global_position.distance_to(_player.global_position)
	_atk_timer = attack_cooldown

	if dist <= attack_range:
		# Close range: anchor slam
		anim.play("slam")
		velocity = Vector2.ZERO
		if _player:
			_player.take_damage(attack_damage)
	else:
		# Mid range: throw metal shard
		anim.play("throw")
		velocity = Vector2.ZERO
		_throw_shard()


func _throw_shard() -> void:
	if not SHARD_SCENE:
		return

	var shard      := SHARD_SCENE.instantiate()
	shard.global_position = global_position
	shard.direction       = (
		_player.global_position - global_position
	).normalized()
	get_parent().add_child(shard)


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/enemies/metal_shard.gd
# Attach to: MetalShard.tscn (Area2D)
# ════════════════════════════════════════════════════════════════

# extends Area2D

# const SPEED   := 100.0
# const DAMAGE  := 6
# const RANGE   := 120.0

# var direction : Vector2 = Vector2.RIGHT
# var _traveled : float   = 0.0

# func _physics_process(delta: float) -> void:
# 	var move    := direction * SPEED * delta
# 	position    += move
# 	_traveled   += move.length()
# 	if _traveled >= RANGE:
# 		queue_free()

# func _on_body_entered(body):
# 	if body.is_in_group("player"):
# 		body.take_damage(DAMAGE)
# 	queue_free()

# ── Uncomment the above and paste into metal_shard.gd ────
# Scene: Area2D > Sprite2D + CollisionShape2D (CircleShape r:3)
# Connect body_entered signal to _on_body_entered


# ── Animations needed in RustedSailor.tscn ───────────────
# walk   4 frames 6fps loop   (heavy limping walk)
# throw  3 frames 8fps once   (wind-up and release)
# slam   4 frames 8fps once   (anchor overhead smash)
# hurt   2 frames 12fps once
# death  5 frames 5fps once   (collapses, rusts away)
