# PUSH 47 — Minimap System
# Commit: "Push 47: Minimap autoload, fog of war, player dot, level bounds"
# File: res://scripts/ui/minimap.gd
# Attach to: SubViewportContainer in HUD.tscn
# ═══════════════════════════════════════════════════════════════
# WHAT THIS DOES:
#   A small 48x32px minimap in the HUD corner.
#   Shows explored areas (fog of war lifts as you walk).
#   Player shown as a white dot.
#   Enemies shown as red dots when nearby.
#   Only active in Seafloor and Border levels (too big to navigate without).
#   Hidden in Hometown, Muynak, USSR (small enough to read directly).
# ═══════════════════════════════════════════════════════════════

extends Control

const MAP_DISPLAY_W : int = 48   # minimap display size in pixels
const MAP_DISPLAY_H : int = 32
const UPDATE_RATE   : float = 0.2   # seconds between redraws

var _level_bounds   : Rect2  = Rect2(0, 0, 1536, 1024)
var _explored       : Array  = []   # grid of bools
var _grid_w         : int    = 48
var _grid_h         : int    = 32
var _update_timer   : float  = 0.0
var _active         : bool   = false
var _player         : Node2D = null

# Colors
const COL_UNEXPLORED := Color(0.05, 0.05, 0.08, 0.9)
const COL_EXPLORED   := Color(0.25, 0.22, 0.18, 0.85)
const COL_PLAYER     := Color(1.0,  1.0,  1.0,  1.0)
const COL_ENEMY      := Color(1.0,  0.2,  0.2,  0.9)
const COL_WELL       := Color(1.0,  0.85, 0.3,  1.0)
const COL_EXIT       := Color(0.3,  1.0,  0.5,  1.0)
const COL_NPC        := Color(0.4,  0.7,  1.0,  1.0)


func _ready() -> void:
	add_to_group("minimap")
	visible = false
	_init_fog()
	GameManager.chapter_changed.connect(_on_chapter_changed)


func _init_fog() -> void:
	_explored.clear()
	for i in _grid_w * _grid_h:
		_explored.append(false)


func activate(level_bounds: Rect2, grid_w: int = 48,
			  grid_h: int = 32) -> void:
	_level_bounds = level_bounds
	_grid_w       = grid_w
	_grid_h       = grid_h
	_active       = true
	visible       = true
	_init_fog()
	_player = get_tree().get_first_node_in_group("player")


func deactivate() -> void:
	_active = false
	visible = false


func _process(delta: float) -> void:
	if not _active or _player == null:
		return
	_update_timer -= delta
	if _update_timer <= 0.0:
		_update_timer = UPDATE_RATE
		_reveal_around_player()
		queue_redraw()


func _reveal_around_player() -> void:
	var cell  := _world_to_grid(_player.global_position)
	var range := 4   # tiles of vision radius
	for dx in range(-range, range + 1):
		for dy in range(-range, range + 1):
			var gx := cell.x + dx
			var gy := cell.y + dy
			if gx >= 0 and gx < _grid_w and gy >= 0 and gy < _grid_h:
				_explored[gy * _grid_w + gx] = true


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var nx := (world_pos.x - _level_bounds.position.x) / _level_bounds.size.x
	var ny := (world_pos.y - _level_bounds.position.y) / _level_bounds.size.y
	return Vector2i(
		int(clamp(nx, 0.0, 1.0) * (_grid_w - 1)),
		int(clamp(ny, 0.0, 1.0) * (_grid_h - 1))
	)


func _grid_to_display(gx: int, gy: int) -> Vector2:
	return Vector2(
		float(gx) / float(_grid_w - 1) * MAP_DISPLAY_W,
		float(gy) / float(_grid_h - 1) * MAP_DISPLAY_H
	)


func _draw() -> void:
	if not _active:
		return

	var cell_w := float(MAP_DISPLAY_W) / float(_grid_w)
	var cell_h := float(MAP_DISPLAY_H) / float(_grid_h)

	# Draw fog grid
	for gy in _grid_h:
		for gx in _grid_w:
			var col  := COL_EXPLORED if _explored[gy * _grid_w + gx] \
						 else COL_UNEXPLORED
			draw_rect(
				Rect2(gx * cell_w, gy * cell_h, cell_w + 0.5, cell_h + 0.5),
				col
			)

	# Draw border
	draw_rect(Rect2(0, 0, MAP_DISPLAY_W, MAP_DISPLAY_H),
		Color(0.5, 0.4, 0.3, 0.8), false, 1.0)

	# Draw points of interest
	_draw_dot_for_group("enemy",   COL_ENEMY,  2.0)
	_draw_dot_for_group("npc",     COL_NPC,    2.0)

	# Draw exit doors
	var exits := get_tree().get_nodes_in_group("level_exit")
	for exit in exits:
		var dp := _world_to_display(exit.global_position)
		draw_circle(dp, 2.0, COL_EXIT)

	# Draw well if activated
	if GameManager.well_activated:
		var well := get_tree().get_first_node_in_group("magic_well")
		if well:
			var dp := _world_to_display(well.global_position)
			draw_circle(dp, 2.5, COL_WELL)

	# Draw player last (always on top)
	if _player:
		var dp := _world_to_display(_player.global_position)
		draw_circle(dp, 2.0, COL_PLAYER)
		# Player direction indicator
		var dir := _player.get_node("AnimatedSprite2D").flip_h
		draw_line(dp, dp + (Vector2.LEFT if dir else Vector2.RIGHT) * 3.0,
			COL_PLAYER, 1.0)


func _draw_dot_for_group(group: String, color: Color,
						  radius: float) -> void:
	var nodes := get_tree().get_nodes_in_group(group)
	for node in nodes:
		if node is Node2D:
			var dp := _world_to_display(node.global_position)
			draw_circle(dp, radius, color)


func _world_to_display(world_pos: Vector2) -> Vector2:
	var nx := (world_pos.x - _level_bounds.position.x) / _level_bounds.size.x
	var ny := (world_pos.y - _level_bounds.position.y) / _level_bounds.size.y
	return Vector2(
		clamp(nx, 0.0, 1.0) * MAP_DISPLAY_W,
		clamp(ny, 0.0, 1.0) * MAP_DISPLAY_H
	)


func _on_chapter_changed(chapter: int) -> void:
	match chapter:
		1, 2, 5:
			deactivate()   # small levels — no minimap needed
		3:
			activate(Rect2(0, 0, 1536, 1024), 48, 32)
		4:
			activate(Rect2(0, 0, 1152, 896),  36, 28)


# ── ADD TO HUD.TSCN ───────────────────────────────────────────
# Control (name: MinimapContainer, minimap.gd)
#   anchor: top-right corner
#   position: (264, 4)   size: (48, 32)
#   custom_minimum_size: (48, 32)
#
# The _draw() function handles all rendering directly.
# No child nodes needed — pure draw calls.
#
# ── ADD TO LEVEL EXIT AREAS ───────────────────────────────────
# In level_door.gd _ready():
#   add_to_group("level_exit")
# Shows as green dot on minimap so player can find the exit.
#
# ── ADD TO MAGIC WELL ─────────────────────────────────────────
# In magic_well.gd _ready():
#   add_to_group("magic_well")
# Shows as gold dot after activation.
