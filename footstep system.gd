extends Node

const STEP_INTERVAL : float = 0.32   # seconds between footstep sounds

var _timer      : float = 0.0
var _tilemap    : TileMapLayer = null
var _player     : CharacterBody2D = null


func _ready() -> void:
	_player = get_parent()


func _process(delta: float) -> void:
	if _player == null:
		return
	if _player.velocity.length() < 10.0:
		_timer = 0.0
		return

	_timer -= delta
	if _timer <= 0.0:
		_timer = STEP_INTERVAL
		_play_step()


func _play_step() -> void:
	if _tilemap == null:
		_tilemap = get_tree().get_first_node_in_group("tilemap")
	if _tilemap == null:
		return

	var cell      := _tilemap.local_to_map(_player.global_position)
	var tile_data := _tilemap.get_cell_tile_data(0, cell)
	var sound     := "footstep_sand"   # default

	if tile_data != null:
		# Read custom data layer named "surface" from TileSet
		# Set this up in TileSet editor:
		#   Add Custom Data Layer named "surface" type String
		#   Set value per tile: "sand", "salt", "grass", "wood", "stone"
		var surface := tile_data.get_custom_data("surface")
		match surface:
			"grass":  sound = "footstep_sand"    # soft
			"sand":   sound = "footstep_sand"
			"salt":   sound = "footstep_salt"    # crunch
			"dirt":   sound = "footstep_sand"
			"wood":   sound = "footstep_wood"    # hollow
			"stone":  sound = "footstep_wood"
			"asphalt":sound = "footstep_wood"
			"parquet":sound = "footstep_wood"    # USSR corridors
			_:        sound = "footstep_sand"

	if AudioManager != null:
		AudioManager.footstep(sound.replace("footstep_", ""))

