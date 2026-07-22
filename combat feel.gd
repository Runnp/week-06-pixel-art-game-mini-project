extends CanvasLayer

@onready var combo_label : Label = $ComboLabel

const COMBO_RESET_TIME : float = 1.5

var _combo_count : int   = 0
var _combo_timer : float = 0.0
var _active      : bool  = false


func _ready() -> void:
	layer              = 9
	combo_label.visible = false


func _process(delta: float) -> void:
	if not _active:
		return
	_combo_timer -= delta
	if _combo_timer <= 0.0:
		_reset_combo()


func register_hit() -> void:
	_combo_count += 1
	_combo_timer  = COMBO_RESET_TIME
	_active       = true

	if _combo_count >= 2:
		combo_label.visible = true
		combo_label.text    = "%d HIT!" % _combo_count
		# Scale pop effect
		combo_label.scale = Vector2(1.4, 1.4)
		var tween := create_tween()
		tween.tween_property(combo_label, "scale",
			Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BOUNCE)

		# Color changes with combo size
		if _combo_count >= 5:
			combo_label.modulate = Color(1.0, 0.4, 0.0)   # orange
		elif _combo_count >= 3:
			combo_label.modulate = Color(1.0, 0.9, 0.2)   # yellow
		else:
			combo_label.modulate = Color.WHITE


func _reset_combo() -> void:
	_combo_count        = 0
	_active             = false
	combo_label.visible = false


# ── ADD TO HUD.TSCN ───────────────────────────────
# CanvasLayer (combo_counter.gd, layer: 9)
# └── Label (name: ComboLabel)
#     position: center-top of screen (160, 40)
#     font size: 12  bold  centered
#
# ── CONNECT TO TOOL HITS ──────────────────────────
# In tool_controller.gd try_use_tool(), after a hit:
#   var combo := get_tree().get_first_node_in_group("combo_counter")
#   if combo: combo.register_hit()
# Add ComboLabel CanvasLayer to group "combo_counter"
