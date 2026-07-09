# PUSH 21 — Trap System (All 6 Traps)
# Commit: "Push 21: All desert traps — sinkhole, chemical, wire, plank, dustdevil, mine"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/world/trap_sinkhole.gd
# Attach to: StaticBody2D placed on open seabed tiles
# ════════════════════════════════════════════════════════════════

extends StaticBody2D

@onready var anim         : AnimatedSprite2D = $AnimatedSprite2D
@onready var warn_area    : Area2D           = $WarnArea
@onready var break_timer  : Timer            = $BreakTimer

var _triggered : bool = false
var _broken    : bool = false


func _ready() -> void:
	warn_area.body_entered.connect(_on_warn_entered)
	break_timer.wait_time = 0.8
	break_timer.one_shot  = true
	break_timer.timeout.connect(_collapse)
	anim.play("safe")


func _on_warn_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _triggered or _broken:
		return
	_triggered = true
	anim.play("warning")
	break_timer.start()


func _collapse() -> void:
	_broken = true
	anim.play("broken")
	$CollisionShape2D.set_deferred("disabled", true)

	var player := get_tree().get_first_node_in_group("player")
	if player and $WarnArea.overlaps_body(player):
		player.take_damage(15)
		# Slow player for 3 seconds
		player.SPEED *= 0.5
		await get_tree().create_timer(3.0).timeout
		player.SPEED *= 2.0

	# Reform after 20 seconds
	await get_tree().create_timer(20.0).timeout
	_triggered = false
	_broken    = false
	$CollisionShape2D.set_deferred("disabled", false)
	anim.play("reform")
	await anim.animation_finished
	anim.play("safe")

# SCENE: StaticBody2D
# ├── AnimatedSprite2D  anims: safe/warning/broken/reform
# ├── CollisionShape2D  RectangleShape2D 32x32
# ├── Area2D (name: WarnArea)
# │   └── CollisionShape2D  CircleShape2D radius:36
# └── Timer (name: BreakTimer)


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/world/trap_chemical.gd
# Attach to: Area2D placed near industrial areas in Muynak
# ════════════════════════════════════════════════════════════════

extends Area2D

@onready var anim : AnimatedSprite2D = $AnimatedSprite2D

const DAMAGE_PER_SEC : float = 5.0
const GROW_INTERVAL  : float = 15.0
const MAX_SCALE      : float = 2.5

var _bodies_inside : Array = []
var _grow_timer    : float = 0.0
var _neutralized   : bool  = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	anim.play("shimmer")


func _process(delta: float) -> void:
	if _neutralized:
		return

	# Damage players inside
	for body in _bodies_inside:
		if is_instance_valid(body) and body.is_in_group("player"):
			body.take_damage(int(DAMAGE_PER_SEC * delta))

	# Slowly grow over time
	_grow_timer += delta
	if _grow_timer >= GROW_INTERVAL and scale.x < MAX_SCALE:
		_grow_timer = 0.0
		var tween   := create_tween()
		tween.tween_property(self, "scale",
			scale + Vector2(0.3, 0.3), 2.0)


func _on_body_entered(body: Node2D) -> void:
	if not body in _bodies_inside:
		_bodies_inside.append(body)


func _on_body_exited(body: Node2D) -> void:
	_bodies_inside.erase(body)


# Called by player using spray_can on this Area2D
func on_tool_used(tool_name: String) -> void:
	if tool_name != "spray_can":
		return
	_neutralized = true
	_bodies_inside.clear()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	await tween.finished
	GameManager.plant_tree()   # neutralized puddle enriches soil
	queue_free()

# SCENE: Area2D
# ├── AnimatedSprite2D  anims: shimmer (iridescent green glow loop)
# └── CollisionShape2D  RectangleShape2D 64x64 (2x2 tiles)


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/world/trap_wire.gd
# Attach to: Area2D stretched across doorways in Muynak
# ════════════════════════════════════════════════════════════════

extends Area2D

@onready var anim        : AnimatedSprite2D = $AnimatedSprite2D
@onready var glint_timer : Timer            = $GlintTimer

var _broken : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	glint_timer.wait_time = 3.0
	glint_timer.timeout.connect(_glint)
	glint_timer.start()
	anim.play("idle")


func _glint() -> void:
	if _broken:
		return
	anim.play("glint")
	await anim.animation_finished
	anim.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _broken:
		return

	_broken = true
	anim.play("snap")

	# Freeze player briefly
	body.can_move = false
	body.take_damage(10)

	await get_tree().create_timer(2.0).timeout
	body.can_move = true

	# Leave broken wire on ground
	await anim.animation_finished
	anim.play("broken")
	set_deferred("monitoring", false)

# SCENE: Area2D
# ├── AnimatedSprite2D  anims: idle/glint/snap/broken
# │   (idle = near-invisible 1-2px line, glint = 1 bright frame)
# └── CollisionShape2D  RectangleShape2D 32x4 (thin tripwire)
# └── Timer (name: GlintTimer)


# ════════════════════════════════════════════════════════════════
# FILE 4: res://scripts/world/trap_plank.gd
# Attach to: StaticBody2D dark floor tiles inside ruins
# ════════════════════════════════════════════════════════════════

extends StaticBody2D

@onready var anim        : AnimatedSprite2D = $AnimatedSprite2D
@onready var break_timer : Timer            = $BreakTimer

var _cracking : bool = false
var _broken   : bool = false

const DAMAGE      : int   = 12
const BREAK_DELAY : float = 0.5


func _ready() -> void:
	break_timer.wait_time = BREAK_DELAY
	break_timer.one_shot  = true
	break_timer.timeout.connect(_break)
	anim.play("normal")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _cracking or _broken:
		return
	_cracking = true
	anim.play("creak")
	_shake()
	break_timer.start()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player") or _broken:
		return
	# Player moved off fast enough — reset
	_cracking = false
	break_timer.stop()
	anim.play("normal")


func _shake() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position",
		position + Vector2(1, 0), 0.06)
	tween.tween_property(self, "position",
		position - Vector2(1, 0), 0.06)
	tween.tween_property(self, "position",
		position, 0.06)


func _break() -> void:
	_broken = true
	anim.play("break")
	$CollisionShape2D.set_deferred("disabled", true)

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.take_damage(DAMAGE)

	await anim.animation_finished
	anim.play("hole")   # permanent hole sprite

# SCENE: StaticBody2D
# ├── AnimatedSprite2D  anims: normal/creak/break/hole
# ├── CollisionShape2D  RectangleShape2D 32x32
# └── Timer (name: BreakTimer)
# Connect body_entered and body_exited signals to this script


# ════════════════════════════════════════════════════════════════
# FILE 5: res://scripts/world/trap_dustdevil.gd
# Attach to: CharacterBody2D — spawned by DustDevilSpawner
# ════════════════════════════════════════════════════════════════

extends CharacterBody2D

const SPEED        : float = 60.0
const DAMAGE       : int   = 8
const KNOCKBACK    : float = 48.0
const DRIFT_FREQ   : float = 0.8   # sine wave frequency

var _direction     : Vector2 = Vector2.RIGHT
var _time          : float   = 0.0
var _map_width     : float   = 640.0   # 20 tiles * 32px


func _ready() -> void:
	$AnimatedSprite2D.play("spin")
	$ContactArea.body_entered.connect(_on_contact)


func setup(dir: Vector2, map_w: float) -> void:
	_direction = dir.normalized()
	_map_width = map_w


func _physics_process(delta: float) -> void:
	_time += delta
	# Sine wave drift perpendicular to travel direction
	var drift    := Vector2(-_direction.y, _direction.x)
	var drift_amt := sin(_time * DRIFT_FREQ) * 15.0
	velocity      = _direction * SPEED + drift * drift_amt
	move_and_slide()

	# Destroy at map edge
	if global_position.x > _map_width or global_position.x < 0:
		queue_free()


func _on_contact(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	body.take_damage(DAMAGE)

	# Knockback
	var knock_dir := (body.global_position - global_position).normalized()
	body.velocity += knock_dir * KNOCKBACK

	# Invert controls briefly
	body.can_move = false
	await get_tree().create_timer(0.3).timeout
	body.can_move = true

# SCENE: CharacterBody2D
# ├── AnimatedSprite2D  anims: spin (4 frames loop — sand column)
# ├── CollisionShape2D  CapsuleShape2D h:24 r:8
# └── Area2D (name: ContactArea)
#     └── CollisionShape2D  CircleShape2D radius:16


# ════════════════════════════════════════════════════════════════
# FILE 6: res://scripts/world/trap_dustdevil_spawner.gd
# Attach to: Node2D at map edge in Seafloor/Border levels
# ════════════════════════════════════════════════════════════════

extends Node2D

const DEVIL_SCENE := preload("res://scenes/world/DustDevil.tscn")

@export var spawn_interval_min : float = 15.0
@export var spawn_interval_max : float = 40.0
@export var map_width          : float = 640.0

@onready var spawn_timer : Timer = $SpawnTimer


func _ready() -> void:
	spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.timeout.connect(_spawn)
	spawn_timer.start()


func _spawn() -> void:
	var devil := DEVIL_SCENE.instantiate()
	devil.global_position = global_position
	devil.setup(Vector2.RIGHT, map_width)   # always moves left→right
	get_parent().add_child(devil)

	# Warn player
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_prompt("⚠ Dust devil approaching!")
		await get_tree().create_timer(2.0).timeout
		hud.hide_prompt()

	spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.start()


# ════════════════════════════════════════════════════════════════
# FILE 7: res://scripts/world/trap_mine.gd
# Attach to: StaticBody2D buried in Border level ground
# ════════════════════════════════════════════════════════════════

extends StaticBody2D

@onready var anim          : AnimatedSprite2D = $AnimatedSprite2D
@onready var countdown_timer : Timer          = $CountdownTimer
@onready var step_area     : Area2D           = $StepArea

const DAMAGE        : int   = 35
const COUNTDOWN     : float = 2.0

var _armed    : bool = true
var _counting : bool = false


func _ready() -> void:
	step_area.body_entered.connect(_on_stepped)
	countdown_timer.wait_time = COUNTDOWN
	countdown_timer.one_shot  = true
	countdown_timer.timeout.connect(_detonate)
	anim.play("buried")   # tiny glint only


func _on_stepped(body: Node2D) -> void:
	if not body.is_in_group("player") or not _armed or _counting:
		return
	_counting = true
	anim.play("countdown")   # rapid red blink
	countdown_timer.start()


func _process(_delta: float) -> void:
	if not _counting:
		return
	# If player moved away in time — cancel
	var player := get_tree().get_first_node_in_group("player")
	if player and not step_area.overlaps_body(player):
		_counting = false
		countdown_timer.stop()
		anim.play("buried")


func _detonate() -> void:
	_armed    = false
	_counting = false
	anim.play("explode")
	ScreenFade.flash(Color.WHITE, 0.2)

	var player := get_tree().get_first_node_in_group("player")
	if player and step_area.overlaps_body(player):
		player.take_damage(DAMAGE)

	await anim.animation_finished
	anim.play("crater")
	$CollisionShape2D.set_deferred("disabled", true)

# SCENE: StaticBody2D
# ├── AnimatedSprite2D  anims: buried/countdown/explode/crater
# ├── CollisionShape2D  RectangleShape2D 8x8 (small buried bump)
# ├── Area2D (name: StepArea)
# │   └── CollisionShape2D  CircleShape2D radius:14
# └── Timer (name: CountdownTimer)
