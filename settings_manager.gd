# PUSH 44 — Settings, Accessibility + Localization Scaffold
# Commit: "Push 44: Settings manager, text size, language scaffold, colorblind mode"
# File: res://scripts/systems/settings_manager.gd
# REGISTER AS AUTOLOAD: Name it "SettingsManager"
# ═══════════════════════════════════════════════════════════════
# WHAT THIS DOES:
#   Persistent settings saved to user://settings.cfg
#   Text size options (important for pixel art readability)
#   Language scaffold (Uzbek, Russian, English to start)
#   Colorblind mode (shifts enemy/trap color palettes)
#   Volume settings (syncs with AudioServer buses)
# ═══════════════════════════════════════════════════════════════

extends Node

const SETTINGS_PATH := "user://settings.cfg"

# Default values
var music_volume    : float = 0.8
var sfx_volume      : float = 1.0
var text_size       : int   = 1      # 0=small 1=normal 2=large
var language        : String = "en"
var colorblind_mode : bool   = false
var screen_shake    : bool   = true
var show_objectives : bool   = true

const TEXT_SIZES := {
	0: 6,    # small  (very tiny, for detail)
	1: 8,    # normal (default pixel font size)
	2: 10,   # large  (better readability)
}

# Language display names
const LANGUAGES := {
	"en": "English",
	"uz": "O'zbek",
	"ru": "Русский",
	"kk": "Қазақша",
}


func _ready() -> void:
	load_settings()
	_apply_all()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio",    "music_volume",    music_volume)
	cfg.set_value("audio",    "sfx_volume",      sfx_volume)
	cfg.set_value("display",  "text_size",       text_size)
	cfg.set_value("display",  "colorblind_mode", colorblind_mode)
	cfg.set_value("display",  "screen_shake",    screen_shake)
	cfg.set_value("gameplay", "show_objectives", show_objectives)
	cfg.set_value("language", "code",            language)
	cfg.save(SETTINGS_PATH)
	print("[Settings] Saved.")


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		print("[Settings] No settings file — using defaults.")
		return

	music_volume    = cfg.get_value("audio",    "music_volume",    0.8)
	sfx_volume      = cfg.get_value("audio",    "sfx_volume",      1.0)
	text_size       = cfg.get_value("display",  "text_size",       1)
	colorblind_mode = cfg.get_value("display",  "colorblind_mode", false)
	screen_shake    = cfg.get_value("display",  "screen_shake",    true)
	show_objectives = cfg.get_value("gameplay", "show_objectives", true)
	language        = cfg.get_value("language", "code",            "en")


func _apply_all() -> void:
	_apply_volumes()
	_apply_text_size()
	_apply_colorblind()


func _apply_volumes() -> void:
	if AudioServer.get_bus_index("Music") >= 0:
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("Music"),
			linear_to_db(music_volume)
		)
	if AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("SFX"),
			linear_to_db(sfx_volume)
		)


func _apply_text_size() -> void:
	# Broadcast to all Label nodes via group
	var size := TEXT_SIZES.get(text_size, 8)
	get_tree().call_group("dialogue_text", "set",
		"theme_override_font_sizes/font_size", size)


func _apply_colorblind() -> void:
	# Shifts specific game colors to colorblind-safe variants
	# Chemical puddle: green → blue-purple
	# Poison trail: yellow-green → orange
	# Only affects shader/modulate — not tile graphics
	get_tree().call_group("colorblind_aware", "set_colorblind_mode",
		colorblind_mode)


func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func set_text_size(index: int) -> void:
	text_size = clamp(index, 0, 2)
	_apply_text_size()
	save_settings()


func set_language(code: String) -> void:
	if not LANGUAGES.has(code):
		return
	language = code
	TranslationServer.set_locale(code)
	save_settings()


func set_colorblind_mode(value: bool) -> void:
	colorblind_mode = value
	_apply_colorblind()
	save_settings()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	save_settings()


func set_show_objectives(value: bool) -> void:
	show_objectives = value
	var panel := get_tree().get_first_node_in_group("objective_panel")
	if panel:
		panel.visible = value
	save_settings()


# ═══════════════════════════════════════════════════════════════
# LOCALIZATION SCAFFOLD
# Save these as .po translation files in res://locale/
# Godot reads them automatically if you add them to:
# Project > Project Settings > Localization > Translations
# ═══════════════════════════════════════════════════════════════
#
# res://locale/en.po — English (base language, already in code)
#
# res://locale/uz.po — Uzbek translation
# msgid "ARAL SEA REVIVAL"
# msgstr "OROL DENGIZINI TIKLASH"
#
# msgid "New Journey"
# msgstr "Yangi Sayohat"
#
# msgid "Continue"
# msgstr "Davom etish"
#
# msgid "Quit"
# msgstr "Chiqish"
#
# msgid "Trees: %d"
# msgstr "Daraxtlar: %d"
#
# msgid "Ships: %d"
# msgstr "Kemalar: %d"
#
# msgid "Fish:  %d"
# msgstr "Baliqlar: %d"
#
# msgid "Objectives"
# msgstr "Maqsadlar"
#
# (Add all game strings here — dialogue stays in JSON files,
#  only UI strings need .po translation)
#
# ── HOW TO USE TR() IN GODOT ─────────────────────────────────
# In any Label:
#   label.text = tr("ARAL SEA REVIVAL")
# Godot automatically returns the translated string
# based on TranslationServer.get_locale()
#
# For dialogue JSON — create parallel JSON files:
#   data/dialogue/bibi_en.json
#   data/dialogue/bibi_uz.json
#   data/dialogue/bibi_ru.json
#
# In dialogue_manager.gd start_from_file():
# REPLACE:
#   var file := FileAccess.open(json_path, FileAccess.READ)
# WITH:
#   var lang := SettingsManager.language
#   var localized := json_path.replace(".json", "_%s.json" % lang)
#   var path := localized if FileAccess.file_exists(localized) else json_path
#   var file := FileAccess.open(path, FileAccess.READ)
#
# This auto-falls back to English if translation missing.
