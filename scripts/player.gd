extends CharacterBody2D

const SPEED = 80.0

@onready var anim = $AnimatedSprite2D

var last_direction := Vector2.DOWN

func _physics_process(delta):
    var input = Vector2(
        Input.get_axis("ui_left", "ui_right"),
        Input.get_axis("ui_up", "ui_down")
    ).normalized()
    
    velocity = input * SPEED
    move_and_slide()
    
    if input != Vector2.ZERO:
        last_direction = input
        _update_anim(input)
    else:
        anim.play("idle_" + _dir_suffix(last_direction))

func _update_anim(dir: Vector2):
    if abs(dir.x) > abs(dir.y):
        anim.play("walk_side")
        anim.flip_h = dir.x < 0
    elif dir.y < 0:
        anim.play("walk_up")
    else:
        anim.play("walk_down")

func _dir_suffix(dir: Vector2) -> String:
    if abs(dir.x) > abs(dir.y): return "side"
    return "up" if dir.y < 0 else "down"
