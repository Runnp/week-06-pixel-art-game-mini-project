# PUSH 04 — Hometown Tilemap
# File: res://scripts/systems/hometown_generator.gd
# Commit: "Push 04: Hometown tilemap, room layout, wall collision"
# Attach to: root Node2D of Hometown.tscn
#
# This auto-generates a placeholder room so you can test
# before hand-painting real pixel art tiles.
# Delete _generate_room() call once you paint tiles manually.

extends Node2D

@onready var tilemap : TileMapLayer = $TileMapLayer

# Atlas coords of your placeholder_tiles.png
# Change these to match whichever tile is grass/wall in your sheet
const TILE_GRASS := Vector2i(0, 0)
const TILE_WALL  := Vector2i(1, 0)
const TILE_SAND  := Vector2i(2, 0)
const TILE_WATER := Vector2i(3, 0)

const ROOM_W := 24
const ROOM_H := 14


func _ready() -> void:
	_generate_room()
	_spawn_player()


func _generate_room() -> void:
	for x in range(ROOM_W):
		for y in range(ROOM_H):
			var cell  := Vector2i(x, y)
			var is_edge := x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1

			if is_edge:
				tilemap.set_cell(cell, 0, TILE_WALL)
			else:
				# Add a strip of sand near the bottom to hint at the dry seabed
				var tile = TILE_SAND if y >= ROOM_H - 4 else TILE_GRASS
				tilemap.set_cell(cell, 0, tile)


func _spawn_player() -> void:
	# Player scene is instanced here at center of room
	# Once you add Player.tscn as a child in the editor you can delete this
	var player_scene := preload("res://scenes/player/Player.tscn")
	var player       := player_scene.instantiate()
	player.global_position = Vector2(ROOM_W / 2 * 32, ROOM_H / 2 * 32)
	add_child(player)


# ── SCENE STRUCTURE FOR Hometown.tscn ────────────────────
# Node2D  (name: Hometown)
# ├── TileMapLayer
# │     TileSet: New TileSet  Tile Size: 32x32
# │     Import your placeholder_tiles.png as Atlas source
# │     Add Physics Layer to TileSet for wall collision
# └── (Player.tscn added as child after Push 05)
