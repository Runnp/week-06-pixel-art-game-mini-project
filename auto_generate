extends Node2D

# This fills a 20×12 tile room (640×384 px) with grass and walls around the border
# Quick blockout generator — DELETE once you hand-paint real levels
# Attach to the Hometown root node

@onready var tilemap: TileMapLayer = $TileMapLayer

const GRASS := Vector2i(0, 0)   # atlas coords of your placeholder tiles
const WALL  := Vector2i(3, 0)

const ROOM_WIDTH := 20
const ROOM_HEIGHT := 12

func _ready() -> void:
    _generate_blockout_room()

func _generate_blockout_room() -> void:
    for x in range(ROOM_WIDTH):
        for y in range(ROOM_HEIGHT):
            var is_edge = x == 0 or y == 0 or x == ROOM_WIDTH - 1 or y == ROOM_HEIGHT - 1
            var coords = Vector2i(x, y)
            var tile = WALL if is_edge else GRASS
            tilemap.set_cell(coords, 0, tile)
