# PUSH 23 — Chapter 4: The Gate Scene + Player Choice
# Commit: "Push 23: Time gate portal, choice UI, chapter 4 scene"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/world/time_gate.gd
# LOCATION: res://scripts/world/time_gate.gd
# Attach to: Area2D "TimeGate" at the bottom of the well in Seafloor.tscn
# Only becomes active AFTER magic_well.gd has fired activate_well()
# ════════════════════════════════════════════════════════════════

extends Area2D

@onready var anim         : AnimatedSprite2D = $AnimatedSprite2D
@onready var glow_light   : PointLight2D     = $GlowLight   # optional 2D light

var _active   : bool = false
var _entered  : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = false   # hidden until well is activated
	GameManager.item_collected.connect(_on_item_collected)


func _on_item_collected(item: String) -> void:
	if item == "well" and not _active:
		_activate()


func _activate() -> void:
	_active = true
	visible = true
	anim.play("portal_open")

	# Pulse glow
	if glow_light:
		var tween := create_tween().set_loops()
		tween.tween_property(glow_light, "energy", 2.0, 1.0)
		tween.tween_property(glow_light, "energy", 0.8, 1.0)

	# Narration
	await get_tree().create_timer(1.5).timeout
	DialogueManager.start([
		{ "speaker": "",       "text": "[The well pulses. Something opens at its base.]" },
		{ "speaker": "Bibi",   "text": "(from far away) The well remembers everything." },
		{ "speaker": "Bibi",   "text": "Even the decisions that should not have been made." },
		{ "speaker": "",       "text": "[A gate. Gold and white. Flickering with old images.]" }
	])


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not _active or _entered:
		return
	_entered = true
	_show_choice()


func _show_choice() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

	DialogueManager.start([
		{ "speaker": "Rustam", "text": "If I could go back... not to fight." },
		{ "speaker": "Rustam", "text": "Just to speak to one person." },
		{ "speaker": "Rustam", "text": "Would that be enough?" },
		{ "speaker": "",       "text": "[The gate responds. It opens fully.]" },
		{ "speaker": "",       "text": "[Go through, or stay?]" }
	])

	await DialogueManager.dialogue_ended

	# Show the choice UI
	var choice_ui := get_tree().get_first_node_in_group("choice_ui")
	if choice_ui:
		choice_ui.show_choice(
			"Step through the gate?",
			"Go through — travel to 1953",
			"Stay — restore the sea from here",
			_go_through,
			_stay_here
		)
	else:
		# Fallback if no choice UI built yet
		_go_through()


func _go_through() -> void:
	GameManager.time_travel_taken = true
	await ScreenFade.fade_out(1.5)
	GameManager.change_scene("res://scenes/levels/USSR.tscn")


func _stay_here() -> void:
	# Original ending route
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true
	DialogueManager.start([
		{ "speaker": "Rustam", "text": "No. The answers are here. In the present." },
		{ "speaker": "Rustam", "text": "I will restore it with my own hands." },
		{ "speaker": "",       "text": "[The gate fades. Head north to the border wall.]" }
	])
	GameManager.change_scene("res://scenes/levels/Border.tscn")

# SCENE: Area2D (name: TimeGate)
# ├── AnimatedSprite2D  anims: portal_open (4 frames), portal_idle (2 frames loop)
# ├── CollisionShape2D  CircleShape2D radius:20
# └── PointLight2D  (name: GlowLight)  color: gold  energy: 1.2


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/ui/choice_ui.gd
# LOCATION: res://scripts/ui/choice_ui.gd
# Attach to: CanvasLayer in HUD.tscn or as standalone scene
# Reusable for any binary player choice in the game
# ════════════════════════════════════════════════════════════════

extends CanvasLayer

signal choice_made(index: int)

@onready var panel       : PanelContainer = $Panel
@onready var prompt_lbl  : Label          = $Panel/VBox/PromptLabel
@onready var btn_a       : Button         = $Panel/VBox/ButtonA
@onready var btn_b       : Button         = $Panel/VBox/ButtonB

var _callback_a : Callable
var _callback_b : Callable


func _ready() -> void:
	add_to_group("choice_ui")
	layer         = 20
	panel.visible = false

	btn_a.pressed.connect(_on_a)
	btn_b.pressed.connect(_on_b)


func show_choice(
	prompt   : String,
	label_a  : String,
	label_b  : String,
	callback_a: Callable,
	callback_b: Callable
) -> void:
	_callback_a   = callback_a
	_callback_b   = callback_b
	prompt_lbl.text = prompt
	btn_a.text      = label_a
	btn_b.text      = label_b
	panel.visible   = true

	# Pause player
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false


func _on_a() -> void:
	panel.visible = false
	emit_signal("choice_made", 0)
	if _callback_a.is_valid():
		_callback_a.call()


func _on_b() -> void:
	panel.visible = false
	emit_signal("choice_made", 1)
	if _callback_b.is_valid():
		_callback_b.call()

# SCENE STRUCTURE FOR ChoiceUI (add to HUD.tscn):
# CanvasLayer (choice_ui.gd, layer: 20)
# └── PanelContainer (name: Panel, centered 200x90)
#     └── VBoxContainer (name: VBox)
#         ├── Label   (name: PromptLabel)  centered
#         ├── Button  (name: ButtonA)
#         └── Button  (name: ButtonB)
