# cotton_specter.gd
# ═══════════════════════════════════════════════════
# LOCATION: res://scripts/enemies/cotton_specter.gd
# ATTACH TO: CharacterBody2D root of CottonSpecter.tscn
# ═══════════════════════════════════════════════════
# WHAT IT DOES:
#   Mini-boss enemy. The Soviet-era agricultural ghost
#   that still tries to irrigate dead fields.
#   Unique mechanics:
#     1. Summons Cotton Boll minions (small crawlers)
#     2. Drain beam — sucks water/health from player
#     3. Dies only after all active minions are killed
#
# SCENE STRUCTURE:
#   CharacterBody2D  (name: CottonSpecter)
#   ├── AnimatedSprite2D
#   ├── CollisionShape2D   CapsuleShape2D h:28 r:10
#   ├── NavigationAgent2D
#   ├── Timer  (name: SummonTimer)   wait_time: 6.0
#   └── Line2D (name: DrainBeam)     width: 2  color: cyan
#
# ANIMATIONS NEEDED:
#   idle      2 frames 4fps loop   (hovering, robes billowing)
#   summon    4 frames 6fps once   (raises arms, minions spawn)
#   drain     3 frames 8fps loop   (beam shoots forward)
#   hurt      2 frames 10fps once
#   death     6 frames 5fps once   (dissolves into cotton wisps)
# ═══════════════════════════════════════════════════

extends "res://scripts/enemies/base_enemy.gd"

const MINION_SCENE   := preload("res://scenes/enemies/CottonBoll.tscn")
const MAX_MINIONS    := 3
const DRAIN_RANGE    := 60.0
const DRAIN_DAMAGE   := 2      # per second while draining
const DRAIN_DURATION := 3.0

var _active_minions : Array  = []
var _draining       : bool   = false
var _drain_timer    : float  = 0.0
var _immune         : bool   = false   # immune while minions are alive


func _on_ready_override() -> void:
	max_health      = 80
	move_speed      = 18.0
	chase_speed     = 35.0
	detect_range    = 130.0
	attack_range    = 20.0
	attack_damage   = 0       # no direct melee — uses drain instead
	attack_cooldown = 0.5
	health          = max_health

	$SummonTimer.timeout.connect(_summon_minions)
	$SummonTimer.start()

	$DrainBeam.visible = false


func _physics_process(delta: float) -> void:
	# Clean up freed minions from list
	_active_minions = _active_minions.filter(func(m): return is_instance_valid(m))
	_immune         = _active_minions.size() > 0

	if _draining:
		_drain_timer -= delta
		if _drain_timer <= 0:
			_stop_drain()

	super(delta)   # run base_enemy physics


# ── Override take_damage — immune while minions live ──
func take_damage(amount: int) -> void:
	if _immune:
		# Flash purple to show immunity
		modulate = Color(0.8, 0.3, 1.0)
		await get_tree().create_timer(0.2).timeout
		modulate = Color.WHITE

		DialogueManager.start([
			{ "speaker": "", "text": "[The Specter is protected while its minions live!]" }
		])
		return

	super(amount)


# ── Custom attack: drain beam instead of melee ────────
func _attack() -> void:
	if _atk_timer > 0 or _draining:
		velocity = Vector2.ZERO
		return

	if _player == null:
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist <= DRAIN_RANGE:
		_start_drain()
	else:
		# Move closer
		state = State.CHASE


func _start_drain() -> void:
	_draining    = true
	_drain_timer = DRAIN_DURATION
	_atk_timer   = DRAIN_DURATION + 0.5
	anim.play("drain")
	$DrainBeam.visible = true
	velocity           = Vector2.ZERO


func _process(delta: float) -> void:
	if not _draining or _player == null:
		return

	# Update beam endpoint toward player
	$DrainBeam.points = [
		Vector2.ZERO,
		to_local(_player.global_position)
	]

	# Deal drain damage
	_player.take_damage(int(DRAIN_DAMAGE * delta))


func _stop_drain() -> void:
	_draining          = false
	$DrainBeam.visible = false
	anim.play("idle")


# ── Summon minions every 6 seconds ───────────────────
func _summon_minions() -> void:
	if state == State.DEAD:
		return

	var needed := MAX_MINIONS - _active_minions.size()
	if needed <= 0:
		return

	anim.play("summon")

	for i in needed:
		var minion := MINION_SCENE.instantiate()
		# Spawn in a ring around the Specter
		var angle  := (TAU / MAX_MINIONS) * (_active_minions.size() + i)
		minion.global_position = global_position + Vector2(cos(angle), sin(angle)) * 40.0
		get_parent().add_child(minion)
		_active_minions.append(minion)


# ═══════════════════════════════════════════════════
# COTTON BOLL MINION — paste into a NEW file:
# res://scripts/enemies/cotton_boll.gd
# Attach to CottonBoll.tscn (CharacterBody2D)
# ═══════════════════════════════════════════════════
#
# extends "res://scripts/enemies/base_enemy.gd"
#
# func _on_ready_override() -> void:
#     max_health     = 8
#     move_speed     = 50.0
#     chase_speed    = 70.0
#     detect_range   = 200.0   # always chases
#     attack_range   = 12.0
#     attack_damage  = 5
#     attack_cooldown = 1.0
#     health         = max_health
#
# func _patrol() -> void:
#     # Minions always beeline for player
#     state = State.CHASE
