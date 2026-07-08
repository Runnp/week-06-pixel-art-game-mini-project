# npc_base.gd
# ═══════════════════════════════════════════════════
# LOCATION: res://scripts/npcs/npc_base.gd
# All NPCs extend this. Never attach directly.
#
# USAGE IN CHILD SCRIPTS:
#   extends "res://scripts/npcs/npc_base.gd"
#   Override _on_interact() for unique dialogue.
#   Set waypoints[] in Inspector per NPC instance.
# ═══════════════════════════════════════════════════

extends CharacterBody2D

# ── Inspector-configurable per NPC ────────────────
@export var move_speed        : float         = 35.0
@export var face_player_range : float         = 96.0   # 3 tiles
@export var waypoints         : Array[Vector2] = []
@export var patrol_loop       : bool          = true
@export var wait_at_waypoint  : float         = 3.0

# ── Node refs ──────────────────────────────────────
@onready var anim : AnimatedSprite2D = $AnimatedSprite2D

# ── Internal state ─────────────────────────────────
enum State { IDLE, WALKING, TALKING }
var state             : State   = State.IDLE
var _current_waypoint : int     = 0
var _wait_timer       : float   = 0.0
var _player           : Node2D  = null
var _waypoint_targets : Array[Vector2] = []


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")

	# Convert local waypoints to global positions
	for wp in waypoints:
		_waypoint_targets.append(global_position + wp)

	add_to_group("npc")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	_on_ready_override()


func _on_ready_override() -> void:
	pass   # child scripts override this


func _physics_process(delta: float) -> void:
	if state == State.TALKING:
		velocity = Vector2.ZERO
		return

	_face_toward_player()

	if _waypoint_targets.is_empty():
		state = State.IDLE
		_play_idle()
		return

	match state:
		State.IDLE:
			_wait_timer -= delta
			if _wait_timer <= 0.0:
				state = State.WALKING
		State.WALKING:
			_walk_to_waypoint()

	move_and_slide()


# ── Walk toward current waypoint ──────────────────
func _walk_to_waypoint() -> void:
	var target := _waypoint_targets[_current_waypoint]
	var diff   := target - global_position

	if diff.length() < 4.0:
		# Reached waypoint
		global_position = target
		velocity        = Vector2.ZERO
		_advance_waypoint()
		return

	var dir  := diff.normalized()
	velocity  = dir * move_speed
	_play_walk(dir)


func _advance_waypoint() -> void:
	_current_waypoint += 1

	if _current_waypoint >= _waypoint_targets.size():
		if patrol_loop:
			_current_waypoint = 0
		else:
			_current_waypoint = _waypoint_targets.size() - 1

	state        = State.IDLE
	_wait_timer  = wait_at_waypoint
	_play_idle()


# ── Rotate toward player when nearby ──────────────
func _face_toward_player() -> void:
	if _player == null:
		return
	if state == State.TALKING:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist > face_player_range:
		return

	var dir := _player.global_position - global_position

	# Flip sprite toward player (horizontal)
	if abs(dir.x) > abs(dir.y):
		anim.flip_h = dir.x < 0


# ── Called by player's InteractRay ────────────────
func interact() -> void:
	if state == State.TALKING:
		return
	state = State.TALKING
	_face_toward_player()
	_on_interact()


# ── Override in child for unique dialogue ─────────
func _on_interact() -> void:
	DialogueManager.start([
		{ "speaker": "", "text": "[They do not respond]" }
	])


func _on_dialogue_ended() -> void:
	if state != State.TALKING:
		return
	await get_tree().create_timer(1.5).timeout
	state       = State.IDLE
	_wait_timer = 1.0


# ── Animation helpers ─────────────────────────────
func _play_idle() -> void:
	if anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation("idle_stand"):
		anim.play("idle_stand")
	elif anim.sprite_frames.has_animation("idle"):
		anim.play("idle")


func _play_walk(dir: Vector2) -> void:
	if anim.sprite_frames == null:
		return

	if abs(dir.x) >= abs(dir.y):
		anim.flip_h = dir.x < 0
		if anim.sprite_frames.has_animation("walk_side"):
			anim.play("walk_side")
	elif dir.y < 0:
		if anim.sprite_frames.has_animation("walk_up"):
			anim.play("walk_up")
	else:
		if anim.sprite_frames.has_animation("walk_down"):
			anim.play("walk_down")
