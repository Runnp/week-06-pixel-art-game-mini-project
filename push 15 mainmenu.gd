# PUSH 15 — Main Menu + Credits + Export
# Commit: "Push 15: Main menu, credits scene, Windows export build"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/ui/main_menu.gd
# Attach to: Control root of MainMenu.tscn
# ════════════════════════════════════════════════════════════════

extends Control

@onready var title_label  : Label  = $VBox/TitleLabel
@onready var start_button : Button = $VBox/StartButton
@onready var quit_button  : Button = $VBox/QuitButton


func _ready() -> void:
	title_label.text  = "ARAL SEA REVIVAL"
	start_button.text = "Begin Journey"
	quit_button.text  = "Quit"

	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)

	# Fade in on load
	modulate.a = 0.0
	var tween  := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.2)


func _on_start() -> void:
	# Reset all progress for a fresh run
	GameManager.current_chapter = 1
	GameManager.trees_planted   = 0
	GameManager.ships_scrapped  = 0
	GameManager.fish_released   = 0
	GameManager.well_activated  = false

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	GameManager.change_scene("res://scenes/levels/Hometown.tscn")


func _on_quit() -> void:
	get_tree().quit()


# ── SCENE STRUCTURE FOR MainMenu.tscn ────────────────────
# Control  (full rect anchor)
# ├── ColorRect  (background — dark sandy color #2C1810)
# ├── TextureRect  (optional: aral sea pixel art background)
# └── VBoxContainer  (name: VBox, centered)
#     ├── Label   (name: TitleLabel)
#     ├── Label   (subtitle: "A story of the Aral Sea")
#     ├── Button  (name: StartButton)
#     └── Button  (name: QuitButton)


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/ui/credits.gd
# Attach to: Control root of Credits.tscn
# ════════════════════════════════════════════════════════════════

extends Control

@onready var scroll_label : Label = $ScrollContainer/CreditsLabel


const CREDITS_TEXT := """
ARAL SEA REVIVAL


Story inspired by
Rustam — environmental activist,
Yale Class of 2026


Game Design & Art
Nurmuhammad Mirzaahmadov (Runnp)


Built with
Godot Engine 4


Dedicated to everyone working
to restore the Aral Sea.


\"The sea was here.
Blue and alive.
We swam in it as children.\"


— Thank you for playing —
"""

var _scroll_y     : float = 600.0
const SCROLL_SPEED := 20.0


func _ready() -> void:
	scroll_label.text = CREDITS_TEXT
	scroll_label.position.y = _scroll_y


func _process(delta: float) -> void:
	scroll_label.position.y -= SCROLL_SPEED * delta

	# After credits finish, return to main menu
	if scroll_label.position.y < -scroll_label.size.y - 40:
		GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

	# Skip credits with any key
	if Input.is_anything_pressed():
		GameManager.change_scene("res://scenes/ui/MainMenu.tscn")


# ════════════════════════════════════════════════════════════════
# EXPORT INSTRUCTIONS (Push 15 final step)
# ════════════════════════════════════════════════════════════════
#
# 1. Project > Export > Add > Windows Desktop
# 2. Download export templates if prompted (Godot will auto-download)
# 3. Set export path: builds/AralSeaRevival.exe
# 4. Click Export Project
# 5. Zip the builds/ folder
# 6. Upload to itch.io
#
# GIT FINAL:
#   git add .
#   git commit -m "Push 15: Main menu, credits, Windows export ready"
#   git push origin main
