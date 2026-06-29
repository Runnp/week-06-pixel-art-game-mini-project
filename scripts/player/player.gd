extends CharacterBody2D

# ── Constants ──────────────────────────────────────────
const SPEED := 80.0

# ── Node references ────────────────────────────────────
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# ── State ──────────────────────────────────────────────
var last_dir := "down"   # tracks facing for idle animation


# ══════════════════════════════════════════════════════
func _physics_process(_delta: float) -> void:
    var input := _get_input()
    velocity = input * SPEED
    move_and_slide()
    _animate(input)


# ── Input ──────────────────────────────────────────────
func _get_input() -> Vector2:
    return Vector2(
        Input.get_axis("ui_left", "ui_right"),
        Input.get_axis("ui_up",   "ui_down")
    ).normalized()


# ── Animation ──────────────────────────────────────────
func _animate(input: Vector2) -> void:
    if input == Vector2.ZERO:
        # Standing still — show idle facing last direction
        anim.play("idle_" + last_dir)
        return

    # Moving — pick walk animation from dominant axis
    if abs(input.x) >= abs(input.y):
        anim.play("walk_side")
        anim.flip_h = input.x < 0   # flip sprite for left movement
        last_dir = "side"
    elif input.y < 0:
        anim.play("walk_up")
        anim.flip_h = false
        last_dir = "up"
    else:
        anim.play("walk_down")
        anim.flip_h = false
        last_dir = "down"
