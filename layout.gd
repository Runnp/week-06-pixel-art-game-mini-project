# PUSH 27 — Hometown Environment: Full Layout
# Commit: "Push 27: Hometown level design, tile zones, environment props"
# File: res://scripts/levels/hometown_layout.gd
# Attach to: root Node2D of Hometown.tscn
# ═══════════════════════════════════════════════════════════════

extends Node2D

# ── WHAT THIS PUSH BUILDS ──────────────────────────────────────
# The full visual layout of Chapter 1 — Rustam's hometown.
# A small Central Asian village on the edge of the dying desert.
# The world is split into 3 zones:
#
#   ZONE A — The Village Core (top half of map)
#     Green-ish, lived-in, dry but not dead yet
#     Bibi's house, Malik's jeep, a small market stall
#     A single sad tree that still has leaves
#
#   ZONE B — The Transition (middle strip)
#     Where grass gives way to sand
#     Cracked earth tiles mixed with sparse dry grass
#     Old irrigation ditch — now completely dry
#     Rusted pipe sticking out of the ground
#
#   ZONE C — The Desert Edge (bottom of map)
#     Pure sand and salt crust
#     Abandoned Soviet signpost (in Russian, weathered)
#     The road Malik's jeep is parked on
#     This is the exit point toward Muynak
#
# MAP SIZE: 32 tiles wide x 20 tiles tall = 1024 x 640 pixels
# ═══════════════════════════════════════════════════════════════

@onready var tilemap : TileMapLayer = $TileMapLayer

# ── TILE ATLAS COORDINATES ─────────────────────────────────────
# These match your placeholder_tiles.png grid (4 columns x 4 rows)
# Replace with real tile coords once you paint the actual tileset

const T_GRASS       := Vector2i(0, 0)   # green ground
const T_DIRT        := Vector2i(1, 0)   # brown dirt path
const T_SAND        := Vector2i(2, 0)   # dry yellow sand
const T_WALL        := Vector2i(3, 0)   # stone/mud wall
const T_CRACK       := Vector2i(0, 1)   # cracked earth
const T_SALT        := Vector2i(1, 1)   # white salt crust
const T_WATER_DRY   := Vector2i(2, 1)   # empty irrigation ditch
const T_PATH        := Vector2i(3, 1)   # dirt road/path

const MAP_W := 32
const MAP_H := 20


func _ready() -> void:
	_paint_zones()
	_add_border_walls()
	await ScreenFade.fade_in()


func _paint_zones() -> void:
	for x in MAP_W:
		for y in MAP_H:
			var cell := Vector2i(x, y)

			# ZONE A — Village (rows 0-7)
			if y <= 7:
				if x == 5 or x == 6 or x == 15 or x == 16:
					tilemap.set_cell(cell, 0, T_DIRT)   # dirt paths between buildings
				else:
					tilemap.set_cell(cell, 0, T_GRASS)

			# ZONE B — Transition (rows 8-12)
			elif y <= 12:
				var noise := (x + y) % 3   # simple checkerboard noise
				if noise == 0:
					tilemap.set_cell(cell, 0, T_CRACK)
				elif noise == 1:
					tilemap.set_cell(cell, 0, T_DIRT)
				else:
					tilemap.set_cell(cell, 0, T_GRASS)

				# Dry irrigation ditch — horizontal strip at row 11
				if y == 11:
					tilemap.set_cell(cell, 0, T_WATER_DRY)

			# ZONE C — Desert Edge (rows 13-19)
			else:
				if y >= 17:
					tilemap.set_cell(cell, 0, T_SALT)
				else:
					tilemap.set_cell(cell, 0, T_SAND)

				# Road at row 18-19
				if y >= 18 and x > 4 and x < 28:
					tilemap.set_cell(cell, 0, T_PATH)


func _add_border_walls() -> void:
	for x in MAP_W:
		tilemap.set_cell(Vector2i(x, 0), 0, T_WALL)
		tilemap.set_cell(Vector2i(x, MAP_H - 1), 0, T_WALL)
	for y in MAP_H:
		tilemap.set_cell(Vector2i(0, y), 0, T_WALL)
		tilemap.set_cell(Vector2i(MAP_W - 1, y), 0, T_WALL)


# ═══════════════════════════════════════════════════════════════
# PROPS TO PLACE MANUALLY IN HOMETOWN.TSCN
# (Add as Sprite2D or StaticBody2D children of Hometown)
# ═══════════════════════════════════════════════════════════════
#
# BIBI'S HOUSE         → tile position (3, 2)   64x64px sprite
#   StaticBody2D with RectangleShape2D 64x32 (collision on lower half)
#   One window with warm light (AnimatedSprite2D — slow flicker at night)
#
# MALIK'S JEEP         → tile position (20, 17)  64x32px sprite
#   StaticBody2D, no interaction, just visual
#   Add dust particle emitter (CPUParticles2D) behind exhaust pipe
#
# LONE TREE            → tile position (8, 5)    32x48px sprite
#   StaticBody2D, CapsuleShape2D radius:4 for trunk collision
#   Still has leaves — only living tree in the whole game world
#
# DRY WELL (village)   → tile position (14, 4)   32x32px sprite
#   StaticBody2D — not the magic well, just aesthetic
#   Interactable: "Just a dry well. Nothing left in it."
#
# MARKET STALL         → tile position (18, 3)   48x32px sprite
#   No interaction, closed/abandoned
#   Faded cloth awning, empty shelves
#
# RUSTED PIPE          → tile position (12, 11)  16x24px sprite
#   StaticBody2D, sticks out of the dry irrigation ditch
#   Interact: "An old Soviet irrigation pipe. Bone dry."
#
# SOVIET SIGNPOST      → tile position (6, 16)   16x48px sprite
#   StaticBody2D
#   Interact: "[The sign is in Russian, faded almost to nothing]"
#             "[You make out the word for COTTON — хлопок]"
#
# DIARY PAGE 01        → tile position (2, 4)    pickup near Bibi's door
#   Area2D with photo_pickup.gd, photo_id: "page_01"
#
# DIARY PAGE 02        → tile position (22, 9)   hidden in transition zone
#   Area2D with photo_pickup.gd, photo_id: "page_02"
#
# SHELTER AREA         → over Bibi's doorway
#   Area2D with shelter.gd — safe from dust storms
#
# LEVEL EXIT DOOR      → tile position (16, 19)  bottom of map
#   Area2D with level_door.gd
#   target_scene: "res://scenes/levels/Muynak.tscn"
#   Only unlocked after talking to Bibi AND Malik
