extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK }

const PATROL_SPEED = 30.0
const CHASE_SPEED = 60.0
const DETECT_RANGE = 120.0
const ATTACK_RANGE = 20.0

var state = State.PATROL
var player: Node2D = null

@onready var anim = $AnimatedSprite2D
@onready var nav = $NavigationAgent2D

func _ready():
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
    match state:
        State.PATROL: _patrol()
        State.CHASE:  _chase()
        State.ATTACK: _attack()
    
    _check_transitions()
    move_and_slide()

func _check_transitions():
    if player == null: return
    var dist = global_position.distance_to(player.global_position)
    
    if dist <= ATTACK_RANGE:
        state = State.ATTACK
    elif dist <= DETECT_RANGE:
        state = State.CHASE
    else:
        state = State.PATROL

func _patrol():
    anim.play("walk")
    # Simple left-right patrol — swap for NavigationAgent2D path later
    velocity = Vector2(PATROL_SPEED, 0)

func _chase():
    anim.play("walk")
    nav.target_position = player.global_position
    var dir = (nav.get_next_path_position() - global_position).normalized()
    velocity = dir * CHASE_SPEED

func _attack():
    anim.play("attack")
    velocity = Vector2.ZERO
