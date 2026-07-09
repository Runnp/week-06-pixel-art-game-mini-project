# PUSH 24 — USSR Level: Tashkent 1953
# Commit: "Push 24: USSR level controller, greyscale shader, 8-min clock"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/levels/ussr_level.gd
# LOCATION: res://scripts/levels/ussr_level.gd
# Attach to: root Node2D of USSR.tscn
# ════════════════════════════════════════════════════════════════

extends Node2D

const TOTAL_TIME   : float = 480.0   # 8 minutes in seconds
const ITEMS_NEEDED : int   = 3

var time_remaining : float = TOTAL_TIME
var items_found    : int   = 0
var _clock_running : bool  = true
var _zorin_signed  : bool  = false

@onready var clock_label  : Label = $HUD_USSR/ClockLabel
@onready var item_label   : Label = $HUD_USSR/ItemLabel
@onready var sign_timer   : Timer = $SignTimer


func _ready() -> void:
	_apply_greyscale()
	_show_arrival_dialogue()

	sign_timer.wait_time = TOTAL_TIME
	sign_timer.one_shot  = true
	sign_timer.timeout.connect(_zorin_signs_early)
	sign_timer.start()

	# Connect evidence pickup signal
	get_tree().call_group("evidence_item", "connect_to_level", self)


func _process(delta: float) -> void:
	if not _clock_running:
		return

	time_remaining -= delta
	time_remaining  = max(time_remaining, 0.0)
	_update_clock_ui()


func _update_clock_ui() -> void:
	var minutes := int(time_remaining) / 60
	var seconds := int(time_remaining) % 60
	clock_label.text = "Time: %02d:%02d" % [minutes, seconds]

	# Clock turns red in last 2 minutes
	if time_remaining < 120.0:
		clock_label.modulate = Color(1.0, 0.2, 0.2)
	elif time_remaining < 240.0:
		clock_label.modulate = Color(1.0, 0.8, 0.2)
	else:
		clock_label.modulate = Color.WHITE


func evidence_collected(item_id: String) -> void:
	items_found += 1
	item_label.text = "Evidence: %d / %d" % [items_found, ITEMS_NEEDED]

	if items_found >= ITEMS_NEEDED:
		_all_evidence_found()


func _all_evidence_found() -> void:
	DialogueManager.start([
		{ "speaker": "",       "text": "[You have everything. Find Minister Zorin before he signs.]" },
		{ "speaker": "Rustam", "text": "Room 14. End of the corridor. I saw his nameplate." }
	])

	# Highlight Zorin's door (glow effect via group signal)
	get_tree().call_group("zorin_door", "highlight")


func _zorin_signs_early() -> void:
	if _zorin_signed or items_found >= ITEMS_NEEDED:
		return
	_zorin_signed    = true
	_clock_running   = false

	DialogueManager.start([
		{ "speaker": "",       "text": "[The signing ceremony begins. Zorin raises his pen.]" },
		{ "speaker": "",       "text": "[You were too late.]" },
		{ "speaker": "Rustam", "text": "No... I needed more time." },
		{ "speaker": "",       "text": "[The gate pulls you back. The past closes.]" }
	])

	await DialogueManager.dialogue_ended
	_trigger_bad_ending()


func _trigger_bad_ending() -> void:
	GameManager.time_travel_taken   = true
	GameManager.zorin_convinced     = false
	await ScreenFade.fade_out(2.0)
	GameManager.change_scene("res://scenes/levels/Border.tscn")


func on_zorin_convinced() -> void:
	_clock_running             = false
	sign_timer.stop()
	GameManager.zorin_convinced = true

	await get_tree().create_timer(3.0).timeout
	await ScreenFade.fade_out(2.0)
	GameManager.change_scene("res://scenes/levels/Border.tscn")


# ── Apply greyscale to entire scene ───────────────
func _apply_greyscale() -> void:
	# Godot 4: use a CanvasLayer with a ColorRect + shader
	# The shader file is defined below (FILE 2)
	var layer     := CanvasLayer.new()
	layer.layer    = 5   # above game, below HUD
	var rect      := ColorRect.new()
	rect.anchors_preset = Control.PRESET_FULL_RECT
	rect.mouse_filter   = Control.MOUSE_FILTER_IGNORE

	var mat  := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/greyscale.gdshader")
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


func _show_arrival_dialogue() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

	DialogueManager.start([
		{ "speaker": "",       "text": "[Tashkent. Soviet Uzbek SSR. 1953.]" },
		{ "speaker": "",       "text": "[The world is grey. Only you carry colour from your time.]" },
		{ "speaker": "Rustam", "text": "The Ministry of Agriculture. I need to find Zorin." },
		{ "speaker": "Rustam", "text": "He signs the river diversion order today." },
		{ "speaker": "Rustam", "text": "But first — I need evidence he cannot ignore." },
		{ "speaker": "",       "text": "[Find 3 items. Then go to Room 14. You have 8 minutes.]" }
	])

	await DialogueManager.dialogue_ended
	if player:
		player.can_move = true


# ════════════════════════════════════════════════════════════════
# FILE 2: res://assets/shaders/greyscale.gdshader
# LOCATION: res://assets/shaders/greyscale.gdshader
# This is a SHADER FILE not a GDScript — save as .gdshader
# ════════════════════════════════════════════════════════════════

# Paste this content into greyscale.gdshader:
#
# shader_type canvas_item;
#
# void fragment() {
#     vec4 color = texture(TEXTURE, UV);
#     float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
#     COLOR = vec4(vec3(grey), color.a * 0.6);
# }
#
# This overlays a 60% opaque greyscale wash over the scene.
# Rustam's sprite appears to "have colour" because he is
# on a layer ABOVE this shader overlay (CanvasLayer layer 6+)


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/world/evidence_item.gd
# LOCATION: res://scripts/world/evidence_item.gd
# Attach to: Area2D for each of the 3 evidence pickups in USSR.tscn
# ════════════════════════════════════════════════════════════════

extends Area2D

@export var evidence_id   : String = "report"
@export var display_name  : String = "Hydrologist's Warning Report"
@export var pickup_text   : String = "A report warning about water loss. Stamped IGNORED."

var _collected : bool = false


func _ready() -> void:
	add_to_group("evidence_item")
	body_entered.connect(_on_body_entered)


func connect_to_level(level: Node) -> void:
	pass   # level connects via get_tree().call_group above


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _collected:
		return
	_collected = true

	DialogueManager.start([
		{ "speaker": "",       "text": "[Found: %s]" % display_name },
		{ "speaker": "Rustam", "text": pickup_text },
		{ "speaker": "",       "text": "[Evidence added to your case]" }
	])

	Inventory.add_item(evidence_id, 1)

	# Notify the level
	var level := get_tree().get_first_node_in_group("ussr_level")
	if level and level.has_method("evidence_collected"):
		level.evidence_collected(evidence_id)

	queue_free()

# ADD to USSR.tscn:
# Group "ussr_level" on the root Node2D
#
# 3 Evidence pickups:
#   Area2D (evidence_item.gd)
#   evidence_id: "report"       display_name: "Hydrologist's Warning Report"
#   pickup_text: "A prediction. Stamped IGNORED in red ink."
#   → Place in: office bin near corridor start
#
#   Area2D (evidence_item.gd)
#   evidence_id: "photograph"   display_name: "Aral Sea 1950 Photograph"
#   pickup_text: "Blue water. A sea so large it has its own weather."
#   → Place in: framed on a corridor wall (interactable)
#
#   Area2D (evidence_item.gd)
#   evidence_id: "letter"       display_name: "Letter from a Karakalpak Fisherman"
#   pickup_text: "He writes to his son about the clean water and the good catch."
#   → Place in: inside a desk drawer in a side room
