# PUSH 30 — Two New Enemies: Salt Crust Crawler + Pesticide Shade
# Commit: "Push 30: SaltCrustCrawler burrow mechanic, PesticideShade poison trail"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/enemies/salt_crust_crawler.gd
# Attach to: CharacterBody2D root of SaltCrustCrawler.tscn
# ════════════════════════════════════════════════════════════════

extends "res://scripts/enemies/base_enemy.gd"

# Burrows underground, pops up near player for surprise attack.
# When burrowed: invisible, no collision, moves fast underground.
# When surfaced: slower, attacks with salt spray AOE.

enum CrawlerState { BURROW, SURFACE, SPRAY }
var crawler_state : CrawlerState = CrawlerState.BURROW

const BURROW_SPEED   : float = 90.0   # fast underground
const SURFACE_RANGE  : float = 40.0   # emerge when within this range of player
const SPRAY_DAMAGE   : int   = 12
const SPRAY_RADIUS   : float = 36.0
const BURROW_TIMER   : float = 3.0    # seconds underground before resurfacing

var _burrow_timer : float = 0.0
var _surfaced     : bool  = false


func _on_ready_override() -> void:
	max_health      = 25
	move_speed      = 90.0
	chase_speed     = 90.0
	detect_range    = 150.0
	attack_range    = SURFACE_RANGE
	attack_damage   = SPRAY_DAMAGE
	attack_cooldown = 2.5
	health          = max_health
	_go_underground()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	match crawler_state:
		CrawlerState.BURROW:
			_burrow_move(delta)
		CrawlerState.SURFACE:
			_surface_idle(delta)
		CrawlerState.SPRAY:
			pass   # handled by animation

	move_and_slide()


func _burrow_move(delta: float) -> void:
	if _player == null:
		return

	# Move toward player underground
	var dir  := (_player.global_position - global_position).normalized()
	velocity  = dir * BURROW_SPEED

	_burrow_timer -= delta
	var dist := global_position.distance_to(_player.global_position)

	# Surface if close enough OR timer ran out
	if dist <= SURFACE_RANGE or _burrow_timer <= 0:
		_emerge()


func _surface_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	if _atk_timer <= 0:
		_spray_attack()


func _go_underground() -> void:
	crawler_state  = CrawlerState.BURROW
	_burrow_timer  = BURROW_TIMER
	_surfaced      = false
	modulate.a     = 0.0   # invisible underground
	$CollisionShape2D.set_deferred("disabled", true)
	anim.play("burrow")


func _emerge() -> void:
	crawler_state = CrawlerState.SURFACE
	_surfaced     = true
	velocity      = Vector2.ZERO

	# Pop up animation
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	$CollisionShape2D.set_deferred("disabled", false)
	anim.play("emerge")

	# Stun the player briefly if they are very close
	if _player:
		var dist := global_position.distance_to(_player.global_position)
		if dist < 24.0:
			_player.can_move = false
			_player.take_damage(6)   # small emerge damage
			await get_tree().create_timer(0.5).timeout
			_player.can_move = true


func _spray_attack() -> void:
	if _atk_timer > 0:
		return
	crawler_state = CrawlerState.SPRAY
	_atk_timer    = attack_cooldown
	anim.play("spray")

	# Salt spray — damage all players in radius
	if _player:
		var dist := global_position.distance_to(_player.global_position)
		if dist <= SPRAY_RADIUS:
			_player.take_damage(SPRAY_DAMAGE)
			# Salt in eyes — brief blur (use ScreenFade flash)
			ScreenFade.flash(Color(1, 1, 0.8, 0.4), 0.4)

	await get_tree().create_timer(0.8).timeout
	crawler_state = CrawlerState.BURROW
	_go_underground()   # retreats underground after spraying

# SCENE: CharacterBody2D (SaltCrustCrawler)
# ├── AnimatedSprite2D  anims: burrow/emerge/idle/spray/hurt/death
# ├── CollisionShape2D  CapsuleShape2D h:16 r:8
# └── NavigationAgent2D
#
# SPRITE NOTES: 32x24px (squat, crab-like shape)
# Colors: white/grey with salt crystal texture
# Burrow = half-submerged, Emerge = burst upward


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/enemies/pesticide_shade.gd
# Attach to: CharacterBody2D root of PesticideShade.tscn
# ════════════════════════════════════════════════════════════════

extends "res://scripts/enemies/base_enemy.gd"

# Floats slowly. Leaves a poison trail that damages over time.
# Poison tiles linger on the ground for 8 seconds after it passes.
# Weak — dies in 2 hits — but its trail is the real danger.

const FLOAT_SPEED    : float = 22.0
const POISON_DAMAGE  : float = 4.0   # per second while in poison
const TRAIL_LIFETIME : float = 8.0
const TRAIL_INTERVAL : float = 0.5   # drop trail every 0.5 seconds

var _trail_timer : float = 0.0
var _poison_zones: Array = []   # track spawned zones for cleanup


func _on_ready_override() -> void:
	max_health      = 15    # very fragile
	move_speed      = FLOAT_SPEED
	chase_speed     = FLOAT_SPEED
	detect_range    = 160.0
	attack_range    = 20.0
	attack_damage   = 8
	attack_cooldown = 1.8
	health          = max_health

	# Floaty sine wave movement offset
	$FloatTimer.timeout.connect(_update_float)
	$FloatTimer.start()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_trail_timer -= delta
	if _trail_timer <= 0:
		_trail_timer = TRAIL_INTERVAL
		_drop_poison_zone()

	super(delta)


func _patrol() -> void:
	# Drift in slow figure-8 pattern
	var t    := Time.get_ticks_msec() / 1000.0
	velocity  = Vector2(
		cos(t * 0.5) * FLOAT_SPEED,
		sin(t) * FLOAT_SPEED * 0.5
	)
	anim.play("float")


func _chase() -> void:
	if _player == null:
		return
	var dir  := (_player.global_position - global_position).normalized()
	velocity  = dir * FLOAT_SPEED
	anim.play("float")


func _drop_poison_zone() -> void:
	# Place a small Area2D poison cloud at current position
	var zone                    := Area2D.new()
	var shape                   := CollisionShape2D.new()
	var circle                  := CircleShape2D.new()
	circle.radius                = 14.0
	shape.shape                  = circle
	zone.add_child(shape)
	zone.global_position         = global_position
	zone.modulate                = Color(0.4, 0.9, 0.3, 0.5)

	get_parent().add_child(zone)
	_poison_zones.append(zone)

	# Damage player if inside
	zone.body_entered.connect(func(body):
		if body.is_in_group("player"):
			body.take_damage(int(POISON_DAMAGE))
	)

	# Fade and remove after lifetime
	var tween := zone.create_tween()
	tween.tween_property(zone, "modulate:a", 0.0, TRAIL_LIFETIME)
	await tween.finished
	_poison_zones.erase(zone)
	zone.queue_free()


func _update_float() -> void:
	# Slight vertical bob — pure visual
	var tween := create_tween()
	tween.tween_property(self, "position:y",
		position.y - 3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y",
		position.y, 0.6).set_trans(Tween.TRANS_SINE)


func _die() -> void:
	# Clean up all poison zones on death
	for zone in _poison_zones:
		if is_instance_valid(zone):
			zone.queue_free()
	_poison_zones.clear()
	super()

# SCENE: CharacterBody2D (PesticideShade)
# ├── AnimatedSprite2D  anims: float (2 frames loop)/emit/hurt/death
# ├── CollisionShape2D  CapsuleShape2D h:20 r:7
# ├── NavigationAgent2D
# └── Timer (name: FloatTimer) wait_time:1.2 autostart:true
#
# SPRITE NOTES: 24x32px (tall wispy shape)
# Colors: sickly green-yellow, semi-transparent (modulate alpha 0.8)
# Float animation: 2 frames, slight shimmer/distortion
# Death: dissolves upward into green mist
