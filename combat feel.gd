# PUSH 36 — Combat Feel: Hit Stop, Knockback, Invincibility Frames
# Commit: "Push 36: Combat juice — hit stop, knockback, iframes, enemy stagger"
# ═══════════════════════════════════════════════════════════════
# WHAT THIS PUSH ADDS:
#   Makes every hit feel impactful.
#   Hit stop = game freezes for 1-3 frames on impact (classic arcade feel)
#   Knockback = enemies fly back when hit
#   iFrames = player cannot be hit again for 0.8 seconds after damage
#   Stagger = enemy briefly freezes and flashes on taking damage
#
# CHANGES TO EXISTING FILES:
#   1. player.gd — add iFrames + knockback reception
#   2. base_enemy.gd — add hit stop + stagger + knockback
#   3. tool_controller.gd — add hit stop call on contact
# ═══════════════════════════════════════════════════════════════

# ════════════════════════════════════════════════════════════════
# CHANGES TO: res://scripts/player/player.gd
# Add these variables and functions to the existing file
# ════════════════════════════════════════════════════════════════

# ADD THESE VARIABLES after "var can_move : bool = true":
#
# var invincible    : bool  = false
# const IFRAME_TIME : float = 0.8
# const KNOCKBACK_RESIST : float = 0.4  # how much knockback is reduced


# REPLACE take_damage() with this version:
#
# func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
#     if invincible:
#         return   # iframe — ignore this hit
#
#     health -= amount
#     health  = clamp(health, 0, MAX_HEALTH)
#     GameManager.emit_signal("player_health_changed", health)
#
#     # Apply knockback
#     if knockback_dir != Vector2.ZERO:
#         velocity += knockback_dir * 120.0 * (1.0 - KNOCKBACK_RESIST)
#
#     # Flash red
#     anim.modulate = Color(1.0, 0.2, 0.2)
#     await get_tree().create_timer(0.1).timeout
#     anim.modulate = Color.WHITE
#
#     # iFrames — cannot be hit again for IFRAME_TIME
#     invincible = true
#     # Blink sprite during iFrames
#     var blink_count := int(IFRAME_TIME / 0.1)
#     for i in blink_count:
#         anim.visible = not anim.visible
#         await get_tree().create_timer(0.1).timeout
#     anim.visible   = true
#     invincible     = false
#
#     if health <= 0:
#         _die()


# ════════════════════════════════════════════════════════════════
# CHANGES TO: res://scripts/enemies/base_enemy.gd
# Replace take_damage() and add hit_stop()
# ════════════════════════════════════════════════════════════════

# REPLACE take_damage() with this version:
#
# func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
#     if state == State.DEAD:
#         return
#
#     health -= amount
#     health  = max(health, 0)
#
#     # Hit stop — freeze game for 2 frames
#     _hit_stop()
#
#     # Knockback
#     if knockback_dir != Vector2.ZERO:
#         velocity = knockback_dir * 160.0
#
#     if health <= 0:
#         _die()
#     else:
#         _stagger()
#
#
# func _hit_stop() -> void:
#     get_tree().paused = true
#     await get_tree().create_timer(0.04).timeout  # ~2 frames at 60fps
#     get_tree().paused = false
#     # Note: process_mode must be ALWAYS on this node or it won't unpause
#     # Set process_mode = Node.PROCESS_MODE_ALWAYS on enemy root node
#
#
# func _stagger() -> void:
#     state    = State.HURT
#     anim.play("hurt")
#     modulate = Color(1.0, 0.3, 0.3)
#
#     # Briefly freeze enemy movement
#     var saved_speed := move_speed
#     move_speed      = 0.0
#
#     await get_tree().create_timer(0.25).timeout
#
#     modulate   = Color.WHITE
#     move_speed = saved_speed
#     state      = State.CHASE


# ════════════════════════════════════════════════════════════════
# CHANGES TO: res://scripts/systems/tool_controller.gd
# Update _play_tool_animation() to pass knockback direction
# ════════════════════════════════════════════════════════════════

# REPLACE the hit_something block in try_use_tool() with:
#
# var hit_something := false
# for target in targets:
#     if target.has_method("on_tool_used"):
#         target.on_tool_used(Inventory.equipped_tool)
#         hit_something = true
#     elif target.has_method("take_damage"):
#         # Direct weapon hit on enemy
#         var knock_dir := (target.global_position - player.global_position).normalized()
#         target.take_damage(_get_tool_damage(), knock_dir)
#         hit_something = true
#
# func _get_tool_damage() -> int:
#     var base_dmg := { "bolgarka": 15, "shovel": 8, "rake": 5 }
#     var tool     := Inventory.equipped_tool
#     var base     := base_dmg.get(tool, 5)
#     var level    := ToolUpgrades.get_level(tool)
#     return base + (level * 5)   # +5 damage per upgrade level


# ════════════════════════════════════════════════════════════════
# NEW FILE: res://scripts/world/combo_counter.gd
# LOCATION: res://scripts/world/combo_counter.gd
# Attach to: CanvasLayer child of HUD.tscn
# Shows combo count when hitting multiple enemies quickly
# ════════════════════════════════════════════════════════════════

extends CanvasLayer

@onready var combo_label : Label = $ComboLabel

const COMBO_RESET_TIME : float = 1.5

var _combo_count : int   = 0
var _combo_timer : float = 0.0
var _active      : bool  = false


func _ready() -> void:
	layer              = 9
	combo_label.visible = false


func _process(delta: float) -> void:
	if not _active:
		return
	_combo_timer -= delta
	if _combo_timer <= 0.0:
		_reset_combo()


func register_hit() -> void:
	_combo_count += 1
	_combo_timer  = COMBO_RESET_TIME
	_active       = true

	if _combo_count >= 2:
		combo_label.visible = true
		combo_label.text    = "%d HIT!" % _combo_count
		# Scale pop effect
		combo_label.scale = Vector2(1.4, 1.4)
		var tween := create_tween()
		tween.tween_property(combo_label, "scale",
			Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BOUNCE)

		# Color changes with combo size
		if _combo_count >= 5:
			combo_label.modulate = Color(1.0, 0.4, 0.0)   # orange
		elif _combo_count >= 3:
			combo_label.modulate = Color(1.0, 0.9, 0.2)   # yellow
		else:
			combo_label.modulate = Color.WHITE


func _reset_combo() -> void:
	_combo_count        = 0
	_active             = false
	combo_label.visible = false


# ── ADD TO HUD.TSCN ───────────────────────────────
# CanvasLayer (combo_counter.gd, layer: 9)
# └── Label (name: ComboLabel)
#     position: center-top of screen (160, 40)
#     font size: 12  bold  centered
#
# ── CONNECT TO TOOL HITS ──────────────────────────
# In tool_controller.gd try_use_tool(), after a hit:
#   var combo := get_tree().get_first_node_in_group("combo_counter")
#   if combo: combo.register_hit()
# Add ComboLabel CanvasLayer to group "combo_counter"
