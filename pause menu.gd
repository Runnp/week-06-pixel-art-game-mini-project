# PUSH 20 — Pause Menu + Settings
# Commit: "Push 20: Pause menu, volume control, save on pause, resume"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/ui/pause_menu.gd
# LOCATION: res://scripts/ui/pause_menu.gd
# Attach to: CanvasLayer root of PauseMenu.tscn
# Add PauseMenu.tscn as child of every level scene
# ════════════════════════════════════════════════════════════════

extends CanvasLayer

@onready var panel          : PanelContainer = $Panel
@onready var resume_btn     : Button         = $Panel/VBox/ResumeButton
@onready var gallery_btn    : Button         = $Panel/VBox/GalleryButton
@onready var save_btn       : Button         = $Panel/VBox/SaveButton
@onready var settings_btn   : Button         = $Panel/VBox/SettingsButton
@onready var quit_btn       : Button         = $Panel/VBox/QuitButton
@onready var settings_panel : Control        = $Panel/SettingsPanel
@onready var music_slider   : HSlider        = $Panel/SettingsPanel/MusicSlider
@onready var sfx_slider     : HSlider        = $Panel/SettingsPanel/SfxSlider

var _paused : bool = false


func _ready() -> void:
	layer          = 10
	panel.visible  = false

	resume_btn.pressed.connect(_resume)
	gallery_btn.pressed.connect(_open_gallery)
	save_btn.pressed.connect(_save_game)
	settings_btn.pressed.connect(_toggle_settings)
	quit_btn.pressed.connect(_quit_to_menu)

	settings_panel.visible = false
	music_slider.value     = AudioServer.get_bus_volume_db(
		AudioServer.get_bus_index("Music")
	)
	sfx_slider.value       = AudioServer.get_bus_volume_db(
		AudioServer.get_bus_index("SFX")
	)

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)


func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("ui_cancel"):
		if _paused:
			_resume()
		else:
			_pause()


func _pause() -> void:
	_paused              = true
	panel.visible        = true
	get_tree().paused    = true

	# Fade in
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _resume() -> void:
	_paused = false
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	await tween.finished
	panel.visible     = false
	get_tree().paused = false


func _open_gallery() -> void:
	var gallery := get_tree().get_first_node_in_group("photo_gallery")
	if gallery:
		gallery.open_gallery()


func _save_game() -> void:
	SaveSystem.save()
	save_btn.text = "Saved ✓"
	await get_tree().create_timer(1.5).timeout
	save_btn.text = "Save Game"


func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible


func _quit_to_menu() -> void:
	get_tree().paused = false
	SaveSystem.save()
	await ScreenFade.fade_out()
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")


func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), value
	)


func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), value
	)


# ════════════════════════════════════════════════════════════════
# GODOT AUDIO BUS SETUP (do this once in AudioServer):
#   Open AudioServer panel (bottom of Godot editor)
#   Add bus: "Music"  — connect to Master
#   Add bus: "SFX"    — connect to Master
#   All music AudioStreamPlayers → Bus: Music
#   All sfx AudioStreamPlayers   → Bus: SFX
# ════════════════════════════════════════════════════════════════

# ── SCENE STRUCTURE FOR PauseMenu.tscn ───────────────────────
# CanvasLayer (pause_menu.gd, layer: 10)
# └── PanelContainer (name: Panel, centered 160x200)
#     ├── VBoxContainer (name: VBox)
#     │   ├── Label       "PAUSED"
#     │   ├── Button      (name: ResumeButton)   "Resume"
#     │   ├── Button      (name: GalleryButton)  "Photos"
#     │   ├── Button      (name: SaveButton)     "Save Game"
#     │   ├── Button      (name: SettingsButton) "Settings"
#     │   └── Button      (name: QuitButton)     "Quit to Menu"
#     └── VBoxContainer (name: SettingsPanel, visible: false)
#         ├── Label   "Music Volume"
#         ├── HSlider (name: MusicSlider) min:-40 max:0 step:1
#         ├── Label   "SFX Volume"
#         └── HSlider (name: SfxSlider)  min:-40 max:0 step:1
#
# Add PauseMenu.tscn as child in:
#   Hometown.tscn, Muynak.tscn, Seafloor.tscn, Border.tscn
# process_mode on PauseMenu CanvasLayer → Always
# (so it still receives input when tree is paused)
