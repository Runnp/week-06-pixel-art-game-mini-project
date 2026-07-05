# screen_fade.gd
# ═══════════════════════════════════════════════════
# LOCATION: res://scripts/systems/screen_fade.gd
# REGISTER AS AUTOLOAD: Name it "ScreenFade"
#   Project > Project Settings > Autoload > +
#   Path: res://scripts/systems/screen_fade.gd
#   Name: ScreenFade
# ═══════════════════════════════════════════════════
# WHAT IT DOES:
#   Global black fade-in / fade-out overlay.
#   Use before every scene transition so it
#   never feels like a jarring hard cut.
#
# USAGE FROM ANY SCRIPT:
#   await ScreenFade.fade_out()          # black in 0.5s
#   GameManager.change_scene(path)
#   await ScreenFade.fade_in()           # black out 0.5s
#
#   Or with custom duration:
#   await ScreenFade.fade_out(1.2)
# ═══════════════════════════════════════════════════

extends CanvasLayer

var _overlay : ColorRect


func _ready() -> void:
	# Always on top of everything
	layer = 100

	_overlay                 = ColorRect.new()
	_overlay.color           = Color(0, 0, 0, 0)
	_overlay.anchors_preset  = Control.PRESET_FULL_RECT
	_overlay.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


# ── Fade TO black (call before changing scene) ────
func fade_out(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, duration)
	await tween.finished


# ── Fade FROM black (call after scene loads) ──────
func fade_in(duration: float = 0.5) -> void:
	_overlay.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, duration)
	await tween.finished


# ── Flash any color (used for hit/well effects) ───
func flash(color: Color = Color.WHITE, duration: float = 0.3) -> void:
	_overlay.color   = Color(color.r, color.g, color.b, 0.0)
	var tween        := create_tween()
	tween.tween_property(_overlay, "color:a", 0.85, duration * 0.3)
	tween.tween_property(_overlay, "color:a", 0.0,  duration * 0.7)
	await tween.finished


# ── HOW TO USE IN LEVEL DOOR (replaces push_05) ───
# func _enter_door() -> void:
#     await ScreenFade.fade_out()
#     GameManager.change_scene(target_scene)
#
# And in every level's _ready():
#     await ScreenFade.fade_in()
