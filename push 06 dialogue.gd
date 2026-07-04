# PUSH 06 — Dialogue System
# Commit: "Push 06: DialogueBox UI, Bibi conversation, NPC trigger"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/ui/dialogue_box.gd
# Attach to: CanvasLayer root of DialogueBox.tscn
# ════════════════════════════════════════════════════════════════

extends CanvasLayer

@onready var panel        : PanelContainer = $PanelContainer
@onready var speaker_label: Label          = $PanelContainer/VBox/SpeakerLabel
@onready var text_label   : Label          = $PanelContainer/VBox/TextLabel
@onready var prompt_label : Label          = $PanelContainer/VBox/PromptLabel

var _full_text    : String = ""
var _char_index   : int    = 0
var _typing       : bool   = false
var _typing_timer : float  = 0.0

const TYPING_SPEED := 0.03  # seconds per character


func _ready() -> void:
	DialogueManager.register_ui(self)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(hide_box)
	panel.visible    = false
	prompt_label.text = "[E] Next"


func _process(delta: float) -> void:
	if not _typing:
		return

	_typing_timer -= delta
	if _typing_timer <= 0.0:
		_typing_timer = TYPING_SPEED
		_char_index  += 1
		text_label.text = _full_text.left(_char_index)

		if _char_index >= _full_text.length():
			_typing = false


func _input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_just_pressed("ui_accept"):
		if _typing:
			# Skip typewriter — show full text immediately
			_typing         = false
			text_label.text = _full_text
		else:
			DialogueManager.advance()


# Called by DialogueManager
func display(speaker: String, text: String) -> void:
	panel.visible        = true
	speaker_label.text   = speaker if speaker != "" else "..."
	_full_text           = text
	_char_index          = 0
	_typing              = true
	_typing_timer        = TYPING_SPEED
	text_label.text      = ""


func hide_box() -> void:
	panel.visible = false


func _on_dialogue_started() -> void:
	panel.visible = true


# ── SCENE STRUCTURE FOR DialogueBox.tscn ─────────────────
# CanvasLayer
# └── PanelContainer  (anchor: bottom center, size: 280x60)
#     └── VBoxContainer  (name: VBox)
#         ├── Label  (name: SpeakerLabel)  font size 8  bold
#         ├── Label  (name: TextLabel)     font size 7  wrap ON
#         └── Label  (name: PromptLabel)   font size 6  align right


# ════════════════════════════════════════════════════════════════
# FILE 2: res://data/dialogue/bibi.json
# Save this as a plain .json file — not a .gd file
# ════════════════════════════════════════════════════════════════

# Paste the content below into bibi.json:
#
# [
#   { "speaker": "",       "text": "[The air smells of salt and dust...]" },
#   { "speaker": "Bibi",   "text": "Rustam, my child. You came back." },
#   { "speaker": "Rustam", "text": "Grandmother. What happened to this place?" },
#   { "speaker": "Bibi",   "text": "The sea was here. Blue and alive. I swam in it as a girl." },
#   { "speaker": "Bibi",   "text": "Now look. Only dust and rust and sick people coughing." },
#   { "speaker": "Rustam", "text": "I read about it at Yale. But seeing it... it is different." },
#   { "speaker": "Bibi",   "text": "Books cannot carry the smell of a dying sea, my child." },
#   { "speaker": "Bibi",   "text": "But maybe your hands can bring some of it back." },
#   { "speaker": "",       "text": "[Bibi points toward the horizon — toward Muynak]" }
# ]


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/npcs/npc_bibi.gd
# Attach to: Bibi NPC scene (CharacterBody2D or StaticBody2D)
# ════════════════════════════════════════════════════════════════

extends StaticBody2D

@export var dialogue_file : String = "res://data/dialogue/bibi.json"
var _talked_today : bool = false


func interact() -> void:
	if _talked_today:
		# Short repeat line if player talks to her again
		DialogueManager.start([
			{ "speaker": "Bibi", "text": "Go, child. Muynak is waiting for you." }
		])
		return

	_talked_today = true
	DialogueManager.start_from_file(dialogue_file)


# ── SCENE STRUCTURE FOR Bibi.tscn ────────────────────────
# StaticBody2D  (name: Bibi)
# ├── AnimatedSprite2D
# ├── CollisionShape2D  (RectangleShape2D  16x24)
# └── (attach npc_bibi.gd)
#
# Place Bibi inside Hometown.tscn
# Player's InteractRay will detect her and call interact()
