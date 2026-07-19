extends AnimatedSprite2D

enum AnimState {
	IDLE_DOWN, IDLE_UP, IDLE_SIDE,
	WALK_DOWN, WALK_UP, WALK_SIDE,
	USE_TOOL,
	HURT,
	DEATH,
}

var current_state  : AnimState = AnimState.IDLE_DOWN
var _locked        : bool      = false   # true during hurt/death/tool
var _last_dir      : String    = "down"
var _facing_right  : bool      = true


func _ready() -> void:
	animation_finished.connect(_on_anim_finished)


# ── Called every frame by player.gd ──────────────────────────
func update_movement(velocity: Vector2) -> void:
	if _locked:
		return

	if velocity == Vector2.ZERO:
		_set_idle()
	else:
		_set_walk(velocity)


func _set_idle() -> void:
	match _last_dir:
		"down": _play_state(AnimState.IDLE_DOWN, "idle_down")
		"up":   _play_state(AnimState.IDLE_UP,   "idle_up")
		"side": _play_state(AnimState.IDLE_SIDE,  "idle_side")


func _set_walk(vel: Vector2) -> void:
	if abs(vel.x) >= abs(vel.y):
		_facing_right = vel.x > 0
		flip_h        = not _facing_right
		_last_dir     = "side"
		_play_state(AnimState.WALK_SIDE, "walk_side")
	elif vel.y < 0:
		flip_h    = false
		_last_dir = "up"
		_play_state(AnimState.WALK_UP, "walk_up")
	else:
		flip_h    = false
		_last_dir = "down"
		_play_state(AnimState.WALK_DOWN, "walk_down")


# ── Called by tool_controller.gd ─────────────────────────────
func play_tool_anim(tool_name: String) -> void:
	var anim_name := "use_" + tool_name
	if sprite_frames and sprite_frames.has_animation(anim_name):
		_locked = true
		_play_state(AnimState.USE_TOOL, anim_name)
	# _locked released in _on_anim_finished


# ── Called by player.gd take_damage() ────────────────────────
func play_hurt() -> void:
	if current_state == AnimState.DEATH:
		return
	_locked = true
	_play_state(AnimState.HURT, "hurt")


# ── Called by player.gd _die() ───────────────────────────────
func play_death() -> void:
	_locked = true
	_play_state(AnimState.DEATH, "death")


func _play_state(state: AnimState, anim_name: String) -> void:
	if current_state == state and is_playing():
		return
	current_state = state
	if sprite_frames and sprite_frames.has_animation(anim_name):
		play(anim_name)


func _on_anim_finished() -> void:
	match current_state:
		AnimState.HURT:
			_locked = false
			_set_idle()
		AnimState.USE_TOOL:
			_locked = false
			_set_idle()
		AnimState.DEATH:
			pass