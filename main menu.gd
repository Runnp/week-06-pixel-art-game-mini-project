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

	
	if scroll_label.position.y < -scroll_label.size.y - 40:
		GameManager.change_scene("res://scenes/ui/MainMenu.tscn")


	if Input.is_anything_pressed():
		GameManager.change_scene("res://scenes/ui/MainMenu.tscn")
