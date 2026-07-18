# PUSH 51 — Player Stats Tracker + End-of-Game Summary
# Commit: "Push 51: Stats tracker autoload, playtime, summary screen before credits"
# File: res://scripts/systems/stats_tracker.gd
# REGISTER AS AUTOLOAD: Name it "StatsTracker"
# ═══════════════════════════════════════════════════════════════
# WHAT THIS DOES:
#   Tracks gameplay stats across the whole run.
#   Displayed on a summary screen just before credits roll.
#   Shows the player the tangible impact of what Rustam did.
#   Emotionally designed — numbers that mean something.
# ═══════════════════════════════════════════════════════════════

extends Node

# ── Tracked stats ─────────────────────────────────
var playtime_seconds  : float = 0.0
var steps_taken       : int   = 0
var tiles_walked      : float = 0.0
var enemies_defeated  : int   = 0
var times_hurt        : int   = 0
var dialogue_lines    : int   = 0
var times_rested      : int   = 0
var storms_survived   : int   = 0
var codex_entries     : int   = 0

var _tracking : bool = true


func _ready() -> void:
	GameManager.chapter_changed.connect(_on_chapter_changed)
	GameManager.player_health_changed.connect(_on_health_changed)
	DialogueManager.dialogue_line_shown.connect(
		func(_s, _t): dialogue_lines += 1
	)


func _process(delta: float) -> void:
	if not _tracking:
		return
	playtime_seconds += delta

	# Count player movement as steps
	var player := get_tree().get_first_node_in_group("player")
	if player and player.velocity.length() > 10.0:
		tiles_walked += player.velocity.length() * delta / 32.0
		if int(tiles_walked) > steps_taken:
			steps_taken = int(tiles_walked)


func register_enemy_kill() -> void:
	enemies_defeated += 1


func register_rest() -> void:
	times_rested += 1


func register_storm_survived() -> void:
	storms_survived += 1


func _on_health_changed(new_health: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and new_health < player.health:
		times_hurt += 1


func _on_chapter_changed(_ch: int) -> void:
	codex_entries = Codex.get_unlocked_by_category("History").size() + \
					Codex.get_unlocked_by_category("Environment").size() + \
					Codex.get_unlocked_by_category("People").size()


func get_playtime_string() -> String:
	var total := int(playtime_seconds)
	var hours := total / 3600
	var mins  := (total % 3600) / 60
	var secs  := total % 60
	if hours > 0:
		return "%dh %02dm" % [hours, mins]
	return "%dm %02ds" % [mins, secs]


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/ui/summary_screen.gd
# Attach to: Control root of SummaryScreen.tscn
# Shown after final cutscene, before Credits.tscn
# ════════════════════════════════════════════════════════════════

# extends Control
#
# @onready var lines_container : VBoxContainer = $Panel/VBox/Lines
# @onready var continue_btn    : Button        = $Panel/ContinueButton
#
# const STAT_LINES := [
#     { "label": "Time with Rustam",    "value": func(): return StatsTracker.get_playtime_string() },
#     { "label": "Steps walked",         "value": func(): return str(StatsTracker.steps_taken) },
#     { "label": "Enemies defeated",     "value": func(): return str(StatsTracker.enemies_defeated) },
#     { "label": "Times rested",         "value": func(): return str(StatsTracker.times_rested) },
#     { "label": "Storms survived",      "value": func(): return str(StatsTracker.storms_survived) },
#     { "label": "Conversations had",    "value": func(): return str(StatsTracker.dialogue_lines) + " lines" },
#     { "label": "Codex entries found",  "value": func(): return str(StatsTracker.codex_entries) + " / 14" },
#     { "label": "Trees planted",        "value": func(): return str(GameManager.trees_planted) },
#     { "label": "Ships scrapped",       "value": func(): return str(GameManager.ships_scrapped) },
#     { "label": "Fish released",        "value": func(): return str(GameManager.fish_released) },
#     { "label": "Photos collected",     "value": func(): return str(Photos.collected_photos().size()) + " / 5" },
# ]
#
# func _ready() -> void:
#     await ScreenFade.fade_in(1.0)
#     continue_btn.pressed.connect(_on_continue)
#     _build_stats()
#
# func _build_stats() -> void:
#     for stat in STAT_LINES:
#         var row   := HBoxContainer.new()
#         var lbl_l := Label.new()
#         var lbl_r := Label.new()
#         lbl_l.text          = stat["label"]
#         lbl_r.text          = stat["value"].call()
#         lbl_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
#         lbl_r.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
#         row.add_child(lbl_l)
#         row.add_child(lbl_r)
#         lines_container.add_child(row)
#         # Stagger appearance
#         row.modulate.a = 0.0
#         var tween := create_tween()
#         tween.tween_property(row, "modulate:a", 1.0, 0.3)
#         await get_tree().create_timer(0.15).timeout
#
# func _on_continue() -> void:
#     await ScreenFade.fade_out(0.8)
#     GameManager.change_scene("res://scenes/ui/Credits.tscn")
#
# ── SCENE STRUCTURE: SummaryScreen.tscn ──────────────────────
# Control (fullrect, summary_screen.gd)
# ├── ColorRect (background dark)
# ├── Label (title: "What Rustam Did" — centered top)
# └── PanelContainer (centered 260x180)
#     └── VBoxContainer (name: VBox)
#         ├── VBoxContainer (name: Lines)  ← stats go here
#         └── Button (name: ContinueButton) text: "To the Sea →"
#
# ── HOW TO INSERT SUMMARY BEFORE CREDITS ─────────────────────
# In rising_water.gd _trigger_ending() replace:
#   GameManager.change_scene("res://scenes/ui/Credits.tscn")
# With:
#   GameManager.change_scene("res://scenes/ui/SummaryScreen.tscn")
#
# ── ADD TO AUTOLOADS ─────────────────────────────────────────
# res://scripts/systems/stats_tracker.gd    Name: StatsTracker
