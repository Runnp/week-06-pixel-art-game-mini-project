# save_system.gd
# ═══════════════════════════════════════════════════
# LOCATION: res://scripts/systems/save_system.gd
# REGISTER AS AUTOLOAD: Name it "SaveSystem"
#   Project > Project Settings > Autoload > +
#   Path: res://scripts/systems/save_system.gd
#   Name: SaveSystem
# ═══════════════════════════════════════════════════
# WHAT IT DOES:
#   Saves and loads game progress to a local file.
#   Call SaveSystem.save() at chapter transitions.
#   Call SaveSystem.load_game() on game boot.
# ═══════════════════════════════════════════════════

extends Node

const SAVE_PATH := "user://aral_save.json"


# ── Save current GameManager state to disk ────────
func save() -> void:
	var data := {
		"chapter":       GameManager.current_chapter,
		"health":        GameManager.player_health,
		"trees":         GameManager.trees_planted,
		"ships":         GameManager.ships_scrapped,
		"fish":          GameManager.fish_released,
		"well":          GameManager.well_activated,
		"inventory":     Inventory.items,
		"equipped":      Inventory.equipped_tool,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: Could not open save file for writing")
		return

	file.store_string(JSON.stringify(data))
	print("[SaveSystem] Game saved.")


# ── Load save file and restore GameManager state ──
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveSystem] No save file found.")
		return false

	var file   := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: Could not open save file for reading")
		return false

	var parsed := JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		push_error("SaveSystem: Corrupt save file")
		return false

	# Restore GameManager
	GameManager.current_chapter  = parsed.get("chapter", 1)
	GameManager.player_health    = parsed.get("health",  100)
	GameManager.trees_planted    = parsed.get("trees",   0)
	GameManager.ships_scrapped   = parsed.get("ships",   0)
	GameManager.fish_released    = parsed.get("fish",    0)
	GameManager.well_activated   = parsed.get("well",    false)

	# Restore Inventory
	Inventory.items         = parsed.get("inventory", {})
	Inventory.equipped_tool = parsed.get("equipped",  "")

	print("[SaveSystem] Game loaded. Chapter: ", GameManager.current_chapter)
	return true


# ── Delete save (used by New Game button) ─────────
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveSystem] Save deleted.")


# ── Check if a save exists (used by main menu) ────
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
