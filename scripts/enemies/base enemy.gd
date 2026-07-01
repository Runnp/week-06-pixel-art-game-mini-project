## base_enemy.gd
## Attached to: every enemy scene (CharacterBody2D)
## Handles: shared state machine, health, damage, death
## Each specific enemy (DustDrifter, RustedSailor etc.)
## extends this script and overrides the STATE methods.
## ─────────────────────────────────────────────────────────
## HOW TO USE:
##   1. Create enemy scene with CharacterBody2D root
##   2. Add AnimatedSprite2D, CollisionShape2D, NavigationAgent2D
##   3. Create a new script that starts with:
##        extends "res://scripts/enemies/base_enemy.gd"
##   4. Override _patrol(), _chase(), _attack() as needed
## ─────────────────────────────────────────────────────────

extends CharacterBody2D

# ── Stats (override in child scripts) ────────────────────
@export var max_health    : int   = 30
@export var move_speed    : float = 40.0
@export var chase_speed   : float = 70.0
@export var detect_range  : float = 100.0
@export var attack_range  : float = 18.0
@export var attack_damage : int   = 10
@export var attack_cooldown: float = 1.2

# ── State machine ─────────────────────────────────────────
enum State { PATROL, CHASE, ATTACK, HURT, DEAD }
var state      : State = State.PATROL
var health     : int   = 0
var _atk_timer : float = 0.0

# ── Node references ───────────────────────────────────────
@onready var anim : AnimatedSprite2D = $AnimatedSprite2D
@onready var nav  : NavigationAgent2D = $NavigationAgent2D

# ── Cached player reference ───────────────────────────────
var _player : Node2D = null


# ══════════════════════════════════════════════════════════
func _ready() -> void:
    health  = max_health
    _player = get_tree().get_first_node_in_group("player")
    _on_ready_override()   # hook for child scripts


# ── Override this in child if you need extra _ready logic ─
func _on_ready_override() -> void:
    pass


func _physics_process(delta: float) -> void:
    if state == State.DEAD:
        return

    _atk_timer -= delta
    _update_state()

    match state:
        State.PATROL: _patrol()
        State.CHASE:  _chase()
        State.ATTACK: _attack()
        State.HURT:   pass   # handled by animation callback

    move_and_slide()


# ── State transitions ─────────────────────────────────────
func _update_state() -> void:
    if _player == null or state == State.HURT:
        return

    var dist := global_position.distance_to(_player.global_position)

    if dist <= attack_range:
        state = State.ATTACK
    elif dist <= detect_range:
        state = State.CHASE
    else:
        state = State.PATROL


# ── Default behaviours (override in child scripts) ────────
func _patrol() -> void:
    anim.play("walk")
    velocity = Vector2(move_speed, 0)   # simple left-right; child overrides this


func _chase() -> void:
    anim.play("walk")
    if _player == null:
        return
    nav.target_position = _player.global_position
    var dir := (nav.get_next_path_position() - global_position).normalized()
    velocity = dir * chase_speed


func _attack() -> void:
    velocity = Vector2.ZERO
    if _atk_timer > 0:
        return

    anim.play("attack")
    _atk_timer = attack_cooldown

    # Deal damage if player still in range
    if _player and global_position.distance_to(_player.global_position) <= attack_range:
        _player.take_damage(attack_damage)


# ── Receive damage from player ────────────────────────────
func take_damage(amount: int) -> void:
    if state == State.DEAD:
        return

    health -= amount
    health  = max(health, 0)

    if health <= 0:
        _die()
    else:
        _hurt_flash()


func _hurt_flash() -> void:
    state = State.HURT
    anim.play("hurt")
    modulate = Color(1, 0.3, 0.3)   # red flash

    await get_tree().create_timer(0.3).timeout

    modulate = Color.WHITE
    state    = State.CHASE   # re-engage after hurt


func _die() -> void:
    state    = State.DEAD
    velocity = Vector2.ZERO
    anim.play("death")
    $CollisionShape2D.set_deferred("disabled", true)

    await anim.animation_finished
    queue_free()
