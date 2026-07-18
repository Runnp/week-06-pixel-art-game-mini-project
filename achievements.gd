# PUSH 48 — Achievement System
# Commit: "Push 48: Achievements autoload, milestone tracking, toast notifications"
# File: res://scripts/systems/achievements.gd
# REGISTER AS AUTOLOAD: Name it "Achievements"
# ═══════════════════════════════════════════════════════════════
# WHAT THIS DOES:
#   Tracks gameplay milestones and displays a small toast
#   notification in the corner when one is earned.
#   Saved to disk — persist across sessions.
#   Completely optional — game works without ever checking these.
#   But they reward thorough exploration and restoration.
# ═══════════════════════════════════════════════════════════════

extends Node

signal achievement_unlocked(id: String)

const SAVE_PATH := "user://achievements.cfg"

const ALL_ACHIEVEMENTS := {
	# ── Story milestones ──────────────────────────
	"first_steps": {
		"title": "First Steps",
		"desc":  "Arrived in Muynak.",
		"icon":  "🚗"
	},
	"the_well": {
		"title": "What the Well Remembers",
		"desc":  "Activated the magic well.",
		"icon":  "💧"
	},
	"footnote": {
		"title": "A Footnote Is Enough",
		"desc":  "Convinced Minister Zorin to add the preservation clause.",
		"icon":  "📝"
	},
	"the_wall": {
		"title": "No Border Here",
		"desc":  "Brought the northern wall down.",
		"icon":  "💥"
	},
	"homecoming": {
		"title": "The Sea Returns",
		"desc":  "Completed the game.",
		"icon":  "🌊"
	},

	# ── Restoration achievements ───────────────────
	"first_tree": {
		"title": "Something Is Growing",
		"desc":  "Planted your first tree on the dry seabed.",
		"icon":  "🌱"
	},
	"seven_trees": {
		"title": "A Small Forest",
		"desc":  "Planted all 7 trees.",
		"icon":  "🌳"
	},
	"scrapper": {
		"title": "Scrapper",
		"desc":  "Scrapped all 3 ships in Muynak.",
		"icon":  "⚙️"
	},
	"fish_keeper": {
		"title": "Fish Keeper",
		"desc":  "Raised 5 fish in the aquarium.",
		"icon":  "🐟"
	},
	"all_soil": {
		"title": "Healer of Land",
		"desc":  "Treated every soil patch on the seafloor.",
		"icon":  "🧪"
	},

	# ── Exploration achievements ───────────────────
	"old_man": {
		"title": "Habit, I Suppose",
		"desc":  "Listened to the old fisherman.",
		"icon":  "🎣"
	},
	"full_codex": {
		"title": "The Full Picture",
		"desc":  "Unlocked all Codex entries.",
		"icon":  "📖"
	},
	"photographer": {
		"title": "Photographer",
		"desc":  "Collected all 5 photographs.",
		"icon":  "📷"
	},
	"archivist": {
		"title": "Archivist",
		"desc":  "Collected all 6 diary pages.",
		"icon":  "📓"
	},

	# ── Survival achievements ──────────────────────
	"storm_survivor": {
		"title": "Storm Survivor",
		"desc":  "Survived a sandstorm without shelter.",
		"icon":  "🌪️"
	},
	"no_damage": {
		"title": "The Land Did Not Break Me",
		"desc":  "Completed a chapter without taking damage.",
		"icon":  "🛡️"
	},
	"pacifist": {
		"title": "I Came to Restore",
		"desc":  "Reached the well without killing any enemies.",
		"icon":  "✌️"
	},

	# ── Secret achievements ────────────────────────
	"bad_ending": {
		"title": "Too Late",
		"desc":  "Zorin signed before you reached him.",
		"icon":  "⏰"
	},
	"stay_here": {
		"title": "Enough",
		"desc":  "Chose to stay in the present instead of time travelling.",
		"icon":  "❤️"
	},
	"read_everything": {
		"title": "Curious Mind",
		"desc":  "Interacted with every prop in Hometown.",
		"icon":  "🔍"
	},
}

var _unlocked       : Array = []
var _chapter_damage : int   = 0   # track for no_damage achievement
var _enemy_kills    : int   = 0   # track for pacifist achievement
var _toast_queue    : Array = []
var _showing_toast  : bool  = false


func _ready() -> void:
	_load()
	GameManager.player_health_changed.connect(_on_health_changed)
	GameManager.chapter_changed.connect(_on_chapter_changed)
	GameManager.item_collected.connect(_on_item_collected)
	Diary.page_collected.connect(_on_diary_page)
	Photos.photo_collected.connect(_on_photo_collected)


func unlock(id: String) -> void:
	if id in _unlocked:
		return
	if not ALL_ACHIEVEMENTS.has(id):
		return
	_unlocked.append(id)
	emit_signal("achievement_unlocked", id)
	_queue_toast(id)
	_save()


func is_unlocked(id: String) -> bool:
	return id in _unlocked


func _queue_toast(id: String) -> void:
	_toast_queue.append(id)
	if not _showing_toast:
		_show_next_toast()


func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_showing_toast = false
		return

	_showing_toast = true
	var id    := _toast_queue.pop_front()
	var data  := ALL_ACHIEVEMENTS[id]

	# Create toast label
	var toast         := Label.new()
	toast.text         = "%s  %s" % [data["icon"], data["title"]]
	toast.position     = Vector2(4, 150)
	toast.modulate.a   = 0.0
	toast.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))

	var canvas        := CanvasLayer.new()
	canvas.layer       = 20
	canvas.add_child(toast)
	get_tree().current_scene.add_child(canvas)

	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.4)
	tween.tween_property(toast, "position:x", 8.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	await tween.finished
	canvas.queue_free()

	await get_tree().create_timer(0.3).timeout
	_show_next_toast()


# ── Auto-unlock listeners ─────────────────────────
func _on_health_changed(new_health: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if new_health < player.MAX_HEALTH:
		_chapter_damage += 1


func _on_chapter_changed(chapter: int) -> void:
	if _chapter_damage == 0 and chapter > 1:
		unlock("no_damage")
	_chapter_damage = 0

	match chapter:
		2: unlock("first_steps")


func _on_item_collected(item: String) -> void:
	match item:
		"tree":
			if GameManager.trees_planted == 1:
				unlock("first_tree")
			if GameManager.trees_planted >= 7:
				unlock("seven_trees")
		"ship_part":
			if GameManager.ships_scrapped >= 3:
				unlock("scrapper")
		"well":
			unlock("the_well")
		"fish":
			if GameManager.fish_released >= 5:
				unlock("fish_keeper")


func _on_diary_page(_page_id: String) -> void:
	if Diary.collected_pages().size() >= Diary.total_pages():
		unlock("archivist")


func _on_photo_collected(_photo_id: String) -> void:
	if Photos.all_collected():
		unlock("photographer")


func register_enemy_killed() -> void:
	_enemy_kills += 1


func check_pacifist() -> void:
	if _enemy_kills == 0:
		unlock("pacifist")


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("achievements", "unlocked", _unlocked)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	_unlocked = cfg.get_value("achievements", "unlocked", [])
