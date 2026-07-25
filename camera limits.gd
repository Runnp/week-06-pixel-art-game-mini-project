extends Node2D

@export var margin : int = 0   # extra pixel padding around edges


func _ready() -> void:
	await get_tree().process_frame   # wait for tilemap to load
	_apply_limits()


func _apply_limits() -> void:
	var tilemap := get_tree().get_first_node_in_group("tilemap")
	if tilemap == null:
		push_warning("CameraLimits: No TileMapLayer in group 'tilemap'")
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var cam := player.get_node_or_null("Camera2D")
	if cam == null:
		return

	var rect      := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	var origin    := tilemap.global_position

	cam.limit_left   = int(origin.x + rect.position.x * tile_size.x) - margin
	cam.limit_top    = int(origin.y + rect.position.y * tile_size.y) - margin
	cam.limit_right  = int(origin.x + (rect.position.x + rect.size.x) * tile_size.x) + margin
	cam.limit_bottom = int(origin.y + (rect.position.y + rect.size.y) * tile_size.y) + margin

	print("[CameraLimits] Set: L%d T%d R%d B%d" % [
		cam.limit_left, cam.limit_top,
		cam.limit_right, cam.limit_bottom
	])
