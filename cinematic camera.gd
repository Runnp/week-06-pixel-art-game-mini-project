extends Node

var _camera      : Camera2D = null
var _letterbox_t : ColorRect = null   # top bar
var _letterbox_b : ColorRect = null   # bottom bar
var _canvas      : CanvasLayer = null
var _default_zoom := Vector2(1.0, 1.0)


func _ready() -> void:
	_canvas       = CanvasLayer.new()
	_canvas.layer = 8   # above world, below HUD
	add_child(_canvas)

	_letterbox_t         = ColorRect.new()
	_letterbox_t.color   = Color.BLACK
	_letterbox_t.size    = Vector2(320, 20)
	_letterbox_t.position = Vector2(0, -20)
	_canvas.add_child(_letterbox_t)

	_letterbox_b         = ColorRect.new()
	_letterbox_b.color   = Color.BLACK
	_letterbox_b.size    = Vector2(320, 20)
	_letterbox_b.position = Vector2(0, 180)   
	_canvas.add_child(_letterbox_b)


# ── Get camera reference once player exists ────────
func init_camera() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		_camera       = player.get_node_or_null("Camera2D")
		_default_zoom = _camera.zoom if _camera else Vector2.ONE


# ── Letterbox in/out ───────────────────────────────
func letterbox_in(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(_letterbox_t, "position:y", 0.0,  duration)
	tween.parallel().tween_property(_letterbox_b, "position:y", 160.0, duration)
	await tween.finished


func letterbox_out(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(_letterbox_t, "position:y", -20.0, duration)
	tween.parallel().tween_property(_letterbox_b, "position:y", 180.0, duration)
	await tween.finished


# ── Zoom in on player ─────────────────────────────
func zoom_in(target_zoom: float = 2.0, duration: float = 1.0) -> void:
	if _camera == null:
		init_camera()
	var tween := create_tween()
	tween.tween_property(_camera, "zoom",
		Vector2(target_zoom, target_zoom), duration).set_trans(Tween.TRANS_SINE)
	await tween.finished


func zoom_out(duration: float = 1.0) -> void:
	if _camera == null:
		return
	var tween := create_tween()
	tween.tween_property(_camera, "zoom",
		_default_zoom, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished


# ── Pan camera to world position, then return ─────
func pan_to(world_pos: Vector2, hold: float = 2.0, duration: float = 1.2) -> void:
	if _camera == null:
		init_camera()
	var player := get_tree().get_first_node_in_group("player")
	if player == null or _camera == null:
		return

	# Detach camera from player temporarily
	_camera.position_smoothing_enabled = false
	var original_pos := _camera.global_position

	var tween := create_tween()
	tween.tween_property(_camera, "global_position", world_pos, duration)
	await tween.finished

	await get_tree().create_timer(hold).timeout

	var return_tween := create_tween()
	return_tween.tween_property(_camera, "global_position",
		player.global_position, duration)
	await return_tween.finished

	_camera.position_smoothing_enabled = true


# ── Screen shake (more control than player.gd version) ──
func shake(strength: float = 4.0, duration: float = 0.4) -> void:
	if _camera == null:
		init_camera()
	var origin := _camera.offset
	var elapsed := 0.0
	while elapsed < duration:
		var t     := elapsed / duration
		var amt   := strength * (1.0 - t)   # diminish over time
		_camera.offset = Vector2(
			randf_range(-amt, amt),
			randf_range(-amt, amt)
		)
		await get_tree().process_frame
		elapsed += get_tree().get_process_delta_time()
	_camera.offset = origin
