## player.gd
## Attached to: scenes/player/Player.tscn (CharacterBody2D)
## Handles: movement, animation, health, interaction trigger
## ─────────────────────────────────────────────────────────

extends CharacterBody2D

# ── Constants ─────────────────────────────────────────────
const SPEED        := 80.0
const MAX_HEALTH   := 100

# ── Node references ───────────────────────────────────────
@onready var anim        : AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_ray: RayCast2D        = $InteractRay

# ── State ─────────────────────────────────────────────────
var health   : int     = MAX_HEALTH
var last_dir : String  = "down"
var can_move : bool    = true   # set false during dialogue/cutscene


# ══════════════════════════════════════════════════════════
func _physics_process(_delta: float) -> void:
    if not can_move:
        velocity = Vector2.ZERO
        return

    var input := _get_input()
    velocity   = input * SPEED
    move_and_slide()
    _animate(input)
    _face_ray(input)

    # Press E or Space to interact with NPCs / objects
    if Input.is_action_just_pressed("ui_accept"):
        _try_interact()


# ── Input ─────────────────────────────────────────────────
func _get_input() -> Vector2:
    return Vector2(
        Input.get_axis("ui_left",  "ui_right"),
        Input.get_axis("ui_up",    "ui_down")
    ).normalized()


# ── Animation ─────────────────────────────────────────────
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


# ── Interaction ray points in facing direction ─────────────
func _face_ray(input: Vector2) -> void:
    if input == Vector2.ZERO:
        return
    interact_ray.target_position = input.normalized() * 24.0


# ── Try to interact with whatever is in front of player ───
func _try_interact() -> void:
    if interact_ray.is_colliding():
        var target = interact_ray.get_collider()
        if target.has_method("interact"):
            target.interact()


# ── Called by enemies when they deal damage ───────────────
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
