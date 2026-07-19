extends Node2D

@onready var nav_region : NavigationRegion2D = $NavigationRegion2D


func _ready() -> void:
	# Small delay to ensure TileMapLayer is fully loaded
	await get_tree().process_frame
	await get_tree().process_frame
	_bake_navigation()


func _bake_navigation() -> void:
	var tilemap := get_tree().get_first_node_in_group("tilemap")
	if tilemap == null:
		push_warning("NavHelper: No TileMapLayer in group 'tilemap'")
		return

	# Get walkable area from tilemap bounds
	var used_rect := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	var world_w   := used_rect.size.x * tile_size.x
	var world_h   := used_rect.size.y * tile_size.y

	var nav_poly  := NavigationPolygon.new()

	# Outer walkable boundary
	var outline := PackedVector2Array([
		Vector2(0, 0),
		Vector2(world_w, 0),
		Vector2(world_w, world_h),
		Vector2(0, world_h),
	])
	nav_poly.add_outline(outline)

	# Add obstacle polygons for each wall/collision tile
	for cell in tilemap.get_used_cells(0):
		var tile_data := tilemap.get_cell_tile_data(0, cell)
		if tile_data == null:
			continue

		# Check if this tile has physics (wall tile)
		if tile_data.get_collision_polygons_count(0) > 0:
			var world_pos := tilemap.map_to_local(cell)
			var half      := Vector2(tile_size) * 0.5
			var obstacle  := PackedVector2Array([
				world_pos - half,
				world_pos + Vector2(half.x, -half.y),
				world_pos + half,
				world_pos + Vector2(-half.x, half.y),
			])
			nav_poly.add_outline(obstacle)

	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
	print("[NavHelper] Navigation baked. Cells: %d" % \
		tilemap.get_used_cells(0).size())
