extends Node

# Parent must be the Player node
@onready var player      : CharacterBody2D = get_parent()
@onready var anim        : AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")
@onready var swing_area  : Area2D          = get_parent().get_node("SwingArea")
@onready var use_timer   : Timer           = $UseTimer

var _on_cooldown : bool = false

# How long each tool takes between uses (seconds)
const TOOL_COOLDOWNS := {
	"shovel":    0.6,
	"rake":      0.5,
	"spray_can": 0.4,
	"bolgarka":  0.8,
	"tnt":       0.0,   # one-time use, no cooldown needed
}

# Upgrade level 1 cuts cooldown by 30%
const UPGRADE_COOLDOWN_REDUCTION := 0.30


func _ready() -> void:
	use_timer.one_shot = true
	use_timer.timeout.connect(func(): _on_cooldown = false)
	Inventory.tool_equipped.connect(_on_tool_changed)


func _on_tool_changed(_tool_name: String) -> void:
	_on_cooldown = false
	use_timer.stop()


# Called by player.gd when E/Space pressed
func try_use_tool() -> void:
	var tool := Inventory.equipped_tool
	if tool == "" or _on_cooldown:
		return

	# Check swing area for valid targets
	var bodies := swing_area.get_overlapping_bodies()
	var areas  := swing_area.get_overlapping_areas()
	var targets : Array = bodies + areas

	var hit_something := false
	for target in targets:
		if target.has_method("on_tool_used"):
			target.on_tool_used(tool)
			hit_something = true

	# Play tool animation regardless of hit
	_play_tool_animation(tool, hit_something)
	_start_cooldown(tool)


func _play_tool_animation(tool: String, hit: bool) -> void:
	match tool:
		"bolgarka":
			anim.play("use_bolgarka")
			if hit:
				_spark_effect()
				_screen_shake(0.15, 3.0)
		"shovel":
			anim.play("use_shovel")
			if hit:
				_dust_puff_effect()
		"rake":
			anim.play("use_rake")
		"spray_can":
			anim.play("use_spray")
			_spray_arc_effect()
		"tnt":
			anim.play("use_tnt")


func _start_cooldown(tool: String) -> void:
	var base     := TOOL_COOLDOWNS.get(tool, 0.5)
	var level    := ToolUpgrades.get_level(tool)
	var cooldown := base * (1.0 - UPGRADE_COOLDOWN_REDUCTION * level)
	_on_cooldown      = true
	use_timer.wait_time = cooldown
	use_timer.start()


# ── Visual feedback functions ──────────────────────
func _spark_effect() -> void:
	# Spawn 4-6 tiny spark particles at swing area center
	for i in randi_range(4, 6):
		var spark    := ColorRect.new()
		spark.size    = Vector2(2, 2)
		spark.color   = Color(1.0, 0.9, 0.3)   # yellow spark
		spark.position = swing_area.position
		player.get_parent().add_child(spark)

		var angle  := randf() * TAU
		var speed  := randf_range(40.0, 90.0)
		var dir    := Vector2(cos(angle), sin(angle))
		var tween  := spark.create_tween()
		tween.tween_property(spark, "position",
			spark.position + dir * speed * 0.3, 0.3)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.3)
		await tween.finished
		spark.queue_free()


func _dust_puff_effect() -> void:
	# Quick brown dust cloud at dig spot
	var puff      := ColorRect.new()
	puff.size      = Vector2(12, 8)
	puff.color     = Color(0.6, 0.45, 0.25, 0.8)
	puff.position  = swing_area.global_position - Vector2(6, 4)
	player.get_parent().add_child(puff)

	var tween := puff.create_tween()
	tween.tween_property(puff, "scale", Vector2(2.0, 1.5), 0.25)
	tween.parallel().tween_property(puff, "modulate:a", 0.0, 0.25)
	await tween.finished
	puff.queue_free()


func _spray_arc_effect() -> void:
	# Green mist arc in front of player
	for i in 5:
		var mist      := ColorRect.new()
		mist.size      = Vector2(3, 3)
		mist.color     = Color(0.3, 0.8, 0.4, 0.7)
		mist.position  = player.global_position
		player.get_parent().add_child(mist)

		var spread := randf_range(-30.0, 30.0)
		var base_dir := player.get_node("InteractRay").target_position.normalized()
		var dir    := base_dir.rotated(deg_to_rad(spread))
		var tween  := mist.create_tween()
		tween.tween_property(mist, "position",
			mist.position + dir * 28.0, 0.4)
		tween.parallel().tween_property(mist, "modulate:a", 0.0, 0.4)
		await tween.finished
		mist.queue_free()


func _screen_shake(duration: float, strength: float) -> void:
	var cam := player.get_node("Camera2D")
	if cam == null:
		return
	var origin := cam.offset
	var tween  := create_tween()
	var steps  := int(duration / 0.05)
	for i in steps:
		var offset := Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(cam, "offset", offset, 0.05)
	tween.tween_property(cam, "offset", origin, 0.05)
