# PUSH 08 — First Enemy: Dust Drifter
# File: res://scripts/enemies/dust_drifter.gd
# Commit: "Push 08: Dust Drifter enemy, state machine, patrol/chase/attack"
# Usage: extends base_enemy.gd — DO NOT attach base_enemy.gd directly

extends "res://scripts/enemies/base_enemy.gd"

# ── Dust Drifter specific stats ───────────────────────────
# (these override the @export vars in base_enemy.gd)
func _on_ready_override() -> void:
	max_health     = 20
	move_speed     = 28.0
	chase_speed    = 55.0
	detect_range   = 90.0
	attack_range   = 16.0
	attack_damage  = 8
	attack_cooldown = 1.5
	health         = max_health

	# Dust cloud timer — emits AOE slow every 4 seconds while chasing
	var dust_timer      := Timer.new()
	dust_timer.wait_time = 4.0
	dust_timer.timeout.connect(_emit_dust_cloud)
	add_child(dust_timer)
	dust_timer.start()


# ── Override patrol: simple left-right bounce ─────────────
var _patrol_dir : int = 1

func _patrol() -> void:
	anim.play("walk")
	velocity = Vector2(move_speed * _patrol_dir, 0)

	# Bounce off walls
	if is_on_wall():
		_patrol_dir *= -1
		anim.flip_h  = _patrol_dir < 0


# ── Dust cloud AOE — slows player if nearby ───────────────
func _emit_dust_cloud() -> void:
	if state != State.CHASE:
		return

	if _player == null:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist < 40.0:
		# Slow player for 2 seconds
		_player.can_move = false
		await get_tree().create_timer(0.4).timeout
		_player.can_move = true
		print("[DustDrifter] Dust cloud slowed player!")


# ── Animations needed in DustDrifter.tscn ────────────────
# walk    4 frames 8fps loop   (shuffling brown blob)
# attack  3 frames 6fps loop   (lurching forward)
# hurt    2 frames 10fps once
# death   4 frames 6fps once   (crumbles to dust)
#
# ── SCENE STRUCTURE FOR DustDrifter.tscn ─────────────────
# CharacterBody2D
# ├── AnimatedSprite2D
# ├── CollisionShape2D   CapsuleShape2D  height:18  radius:6
# └── NavigationAgent2D
#     target_desired_distance: 4.0
