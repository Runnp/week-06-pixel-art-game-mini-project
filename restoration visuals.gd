# PUSH 37 — Restoration Visuals: World Changes as Rustam Heals the Land
# Commit: "Push 37: World state visuals, tile restoration, tree growth, water return"
# ═══════════════════════════════════════════════════════════════
# WHAT THIS PUSH DOES:
#   The world visually changes as restoration progress increases.
#   This is the game's most powerful feedback loop.
#   When Rustam does good — the world looks better.
#   Tangibly. Visibly. In real time.
# ═══════════════════════════════════════════════════════════════

# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/systems/world_state.gd
# LOCATION: res://scripts/systems/world_state.gd
# REGISTER AS AUTOLOAD: Name it "WorldState"
#   Project > Project Settings > Autoload > +
#   Name: WorldState
# ════════════════════════════════════════════════════════════════

extends Node

signal world_changed(restoration_percent: float)

# Restoration percentage 0.0 to 1.0
# Drives: sky color, ambient light, background haze intensity
# Updated whenever GameManager emits item_collected

const MAX_TREES : int = 7
const MAX_SHIPS : int = 3
const MAX_FISH  : int = 5

var _sky_overlay   : ColorRect = null
var _canvas        : CanvasLayer = null


func _ready() -> void:
	GameManager.item_collected.connect(_on_item_collected)

	# Sky color overlay — tints the whole world subtly
	_canvas       = CanvasLayer.new()
	_canvas.layer = 2   # above tiles, below everything else
	add_child(_canvas)

	_sky_overlay         = ColorRect.new()
	_sky_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_sky_overlay.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_sky_overlay.color          = Color(0.6, 0.45, 0.2, 0.3)   # start: dusty orange
	_canvas.add_child(_sky_overlay)


func get_restoration_percent() -> float:
	var trees := min(GameManager.trees_planted,  MAX_TREES)
	var ships := min(GameManager.ships_scrapped, MAX_SHIPS)
	var fish  := min(GameManager.fish_released,  MAX_FISH)
	return (trees + ships + fish) / float(MAX_TREES + MAX_SHIPS + MAX_FISH)


func _on_item_collected(_item: String) -> void:
	var pct := get_restoration_percent()
	emit_signal("world_changed", pct)
	_update_sky(pct)


func _update_sky(pct: float) -> void:
	# 0.0 = dusty orange haze (start of game)
	# 0.5 = lighter, less haze
	# 1.0 = clear blue tint (restored world)
	var start_color := Color(0.6, 0.45, 0.2, 0.3)
	var end_color   := Color(0.3, 0.5,  0.9, 0.1)
	var new_color   := start_color.lerp(end_color, pct)

	var tween := create_tween()
	tween.tween_property(_sky_overlay, "color", new_color, 2.0)


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/world/tree_growth.gd
# LOCATION: res://scripts/world/tree_growth.gd
# Attach to: Node2D "TreeGrowth" placed at each tree_spot location
# Shows a sapling that grows into a full tree over time
# ════════════════════════════════════════════════════════════════

extends Node2D

@onready var sprite : Sprite2D = $Sprite2D

# Tree grows through 4 stages:
# 0 = empty ground (no sprite)
# 1 = tiny sprout  (8x8px region of spritesheet)
# 2 = sapling      (16x20px)
# 3 = young tree   (24x32px)
# 4 = full tree    (32x48px)  ← tallest, sticks above 32px tile

var _stage        : int   = 0
var _grow_timer   : float = 0.0
const GROW_TIME   : float = 20.0   # seconds per growth stage
const FRAME_MAP   : Array = [0, 1, 2, 3, 4]  # spritesheet frames


func _ready() -> void:
	sprite.visible = false
	WorldState.world_changed.connect(_on_world_changed)


func plant() -> void:
	if _stage > 0:
		return
	_stage         = 1
	sprite.visible = true
	sprite.frame   = FRAME_MAP[_stage]
	_grow_timer    = GROW_TIME


func _process(delta: float) -> void:
	if _stage == 0 or _stage >= 4:
		return
	_grow_timer -= delta
	if _grow_timer <= 0.0:
		_advance_stage()


func _advance_stage() -> void:
	_stage      = min(_stage + 1, 4)
	_grow_timer = GROW_TIME
	sprite.frame = FRAME_MAP[_stage]

	# Scale pop when growing
	sprite.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(sprite, "scale",
		Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE)

	if _stage == 4:
		_fully_grown()


func _fully_grown() -> void:
	# Add collision so player cannot walk through full tree
	var body  := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var cap   := CapsuleShape2D.new()
	cap.height = 12
	cap.radius = 5
	shape.shape = cap
	body.add_child(shape)
	body.position = Vector2(0, 8)   # at trunk base
	add_child(body)


func _on_world_changed(pct: float) -> void:
	# Higher restoration = trees grow slightly faster
	if _stage > 0 and _stage < 4:
		_grow_timer = max(_grow_timer - (pct * 5.0), 1.0)


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/world/water_puddle_spawner.gd
# LOCATION: res://scripts/world/water_puddle_spawner.gd
# Attach to: Node2D placed near the magic well after activation
# Small puddles of water appear as restoration progresses
# Visual hint that water is returning long before the finale
# ════════════════════════════════════════════════════════════════

extends Node2D

const PUDDLE_SPRITE_FRAME := 0   # water tile from your tileset
var _puddles_spawned : int = 0
var _max_puddles     : int = 5


func _ready() -> void:
	visible = false   # hidden until well activated
	GameManager.item_collected.connect(_on_item_collected)


func activate() -> void:
	visible = true


func _on_item_collected(_item: String) -> void:
	if not visible:
		return
	if _puddles_spawned >= _max_puddles:
		return

	var pct := WorldState.get_restoration_percent()
	if pct < 0.3:
		return   # not enough progress yet

	_spawn_puddle()


func _spawn_puddle() -> void:
	_puddles_spawned += 1

	var puddle      := Sprite2D.new()
	puddle.frame     = PUDDLE_SPRITE_FRAME
	puddle.modulate  = Color(0.4, 0.7, 1.0, 0.0)   # start invisible
	puddle.position  = Vector2(
		randf_range(-48.0, 48.0),
		randf_range(-24.0, 24.0)
	)
	add_child(puddle)

	# Fade in slowly
	var tween := puddle.create_tween()
	tween.tween_property(puddle, "modulate:a", 0.6, 3.0)

	# Gentle shimmer animation
	var shimmer := puddle.create_tween().set_loops()
	shimmer.tween_property(puddle, "modulate:a", 0.9, 1.2)
	shimmer.tween_property(puddle, "modulate:a", 0.5, 1.2)

# ── HOW TO USE ────────────────────────────────────
# Place Node2D with water_puddle_spawner.gd near the well
# In magic_well.gd activate_well(), after the sequence:
#   var spawner := get_tree().get_first_node_in_group("puddle_spawner")
#   if spawner: spawner.activate()
# Add spawner to group "puddle_spawner" in _ready()
