# PUSH 34 — Camera System: Cinematic Moments + Screen Effects
# Commit: "Push 34: Cinematic camera, letterbox, zoom, pan sequences"
# File: res://scripts/systems/cinematic_camera.gd
# REGISTER AS AUTOLOAD: Name it "CinematicCamera"
#   Project > Project Settings > Autoload > +
#   Name: CinematicCamera
# ═══════════════════════════════════════════════════════════════
# WHAT THIS DOES:
#   Controls the Camera2D on the player for dramatic moments.
#   Letterboxing (black bars), slow zoom in/out, camera pan
#   to a point of interest, then return to player.
#   Used for: well activation, TNT explosion, ending swim.
# ═══════════════════════════════════════════════════════════════

extends Node

var _camera      : Camera2D = null
var _letterbox_t : ColorRect = null   # top bar
var _letterbox_b : ColorRect = null   # bottom bar
var _canvas      : CanvasLayer = null
var _default_zoom := Vector2(1.0, 1.0)


func _ready() -> void:
	# Build letterbox overlay
	_canvas       = CanvasLayer.new()
	_canvas.layer = 8   # above world, below HUD
	add_child(_canvas)

	_letterbox_t         = ColorRect.new()
	_letterbox_t.color   = Color.BLACK
	_letterbox_t.size    = Vector2(320, 20)
	_letterbox_t.position = Vector2(0, -20)   # hidden above screen
	_canvas.add_child(_letterbox_t)

	_letterbox_b         = ColorRect.new()
	_letterbox_b.color   = Color.BLACK
	_letterbox_b.size    = Vector2(320, 20)
	_letterbox_b.position = Vector2(0, 180)   # hidden below screen
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


# ═══════════════════════════════════════════════════════════════
# CINEMATIC SEQUENCES — how to use CinematicCamera in scripts
# ═══════════════════════════════════════════════════════════════
#
# WELL ACTIVATION (in magic_well.gd _play_sacrifice_effect):
#   CinematicCamera.init_camera()
#   await CinematicCamera.letterbox_in(0.8)
#   await CinematicCamera.zoom_in(1.8, 1.5)
#   ScreenFade.flash(Color(0.6, 0.0, 0.0), 0.6)   # blood red
#   await get_tree().create_timer(1.0).timeout
#   ScreenFade.flash(Color.WHITE, 0.4)              # rebirth white
#   await CinematicCamera.zoom_out(1.0)
#   await CinematicCamera.letterbox_out(0.5)
#
# TNT EXPLOSION (in north_wall.gd _detonate):
#   await CinematicCamera.letterbox_in(0.3)
#   await CinematicCamera.shake(6.0, 0.5)
#   ScreenFade.flash(Color.WHITE, 0.25)
#   await CinematicCamera.pan_to(wall_center_pos, 3.0, 1.0)
#   await CinematicCamera.letterbox_out(0.8)
#
# ENDING SWIM (in rising_water.gd _trigger_ending):
#   await CinematicCamera.letterbox_in(1.0)
#   await CinematicCamera.zoom_in(1.5, 3.0)
#   # Player swims toward sunset — camera follows slowly
#   await get_tree().create_timer(8.0).timeout
#   await ScreenFade.fade_out(3.0)
#
# MALIK JEEP CUTSCENE (in npc_malik.gd _trigger_travel_cutscene):
#   await CinematicCamera.letterbox_in(0.5)
#   await CinematicCamera.pan_to(jeep_position, 2.0, 0.8)
#   await CinematicCamera.letterbox_out(0.4)
#
# GUARD HANDSHAKE (in border level after TNT):
#   await CinematicCamera.letterbox_in(0.4)
#   await CinematicCamera.zoom_in(1.6, 1.0)
#   await get_tree().create_timer(2.5).timeout
#   await CinematicCamera.zoom_out(0.8)
#   await CinematicCamera.letterbox_out(0.4)
