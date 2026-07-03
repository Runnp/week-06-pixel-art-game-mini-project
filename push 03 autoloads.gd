# PUSH 03 — Autoloads
# Commit: "Push 03: GameManager, DialogueManager, Inventory autoloads"
#
# REGISTER ALL THREE IN:
#   Project > Project Settings > Autoload > click +
#
#   res://scripts/systems/game_manager.gd      Name: GameManager
#   res://scripts/systems/dialogue_manager.gd  Name: DialogueManager
#   res://scripts/systems/inventory.gd         Name: Inventory
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/systems/game_manager.gd
# ════════════════════════════════════════════════════════════════

extends Node

signal player_health_changed(new_health: int)
signal player_died
signal chapter_changed(chapter_number: int)
signal item_collected(item_name: String)

var current_chapter : int  = 1
var player_health   : int  = 100
var trees_planted   : int  = 0
var ships_scrapped  : int  = 0
var fish_released   : int  = 0
var well_activated  : bool = false

const CHAPTER_SCENES := {
	1: "res://scenes/levels/Hometown.tscn",
	2: "res://scenes/levels/Muynak.tscn",
	3: "res://scenes/levels/Seafloor.tscn",
	4: "res://scenes/levels/Border.tscn",
}

func _ready() -> void:
	player_health_changed.connect(_on_health_changed)
	player_died.connect(_on_player_died)

func advance_chapter() -> void:
	current_chapter += 1
	emit_signal("chapter_changed", current_chapter)
	if CHAPTER_SCENES.has(current_chapter):
		change_scene(CHAPTER_SCENES[current_chapter])

func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func plant_tree() -> void:
	trees_planted += 1
	emit_signal("item_collected", "tree")

func scrap_ship() -> void:
	ships_scrapped += 1
	emit_signal("item_collected", "ship_part")

func release_fish() -> void:
	fish_released += 1
	emit_signal("item_collected", "fish")

func activate_well() -> void:
	well_activated = true
	emit_signal("item_collected", "well")

func _on_health_changed(new_health: int) -> void:
	player_health = new_health

func _on_player_died() -> void:
	await get_tree().create_timer(1.5).timeout
	change_scene(CHAPTER_SCENES[current_chapter])


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/systems/dialogue_manager.gd
# ════════════════════════════════════════════════════════════════

extends Node

signal dialogue_started
signal dialogue_line_shown(speaker: String, text: String)
signal dialogue_ended

var active       : bool  = false
var _lines       : Array = []
var _index       : int   = 0
var _dialogue_ui : Node  = null

func register_ui(ui_node: Node) -> void:
	_dialogue_ui = ui_node

func start_from_file(json_path: String) -> void:
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: Cannot open %s" % json_path)
		return
	var parsed := JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Array:
		push_error("DialogueManager: Invalid JSON in %s" % json_path)
		return
	start(parsed)

func start(lines: Array) -> void:
	if active:
		return
	_lines  = lines
	_index  = 0
	active  = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
	emit_signal("dialogue_started")
	_show_current_line()

func advance() -> void:
	if not active:
		return
	_index += 1
	if _index >= _lines.size():
		_end()
	else:
		_show_current_line()

func _show_current_line() -> void:
	var line    : Dictionary = _lines[_index]
	var speaker : String     = line.get("speaker", "")
	var text    : String     = line.get("text",    "")
	emit_signal("dialogue_line_shown", speaker, text)
	if _dialogue_ui and _dialogue_ui.has_method("display"):
		_dialogue_ui.display(speaker, text)

func _end() -> void:
	active = false
	_lines = []
	_index = 0
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true
	if _dialogue_ui and _dialogue_ui.has_method("hide_box"):
		_dialogue_ui.hide_box()
	emit_signal("dialogue_ended")


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/systems/inventory.gd
# ════════════════════════════════════════════════════════════════

extends Node

signal item_added(item_name: String, new_count: int)
signal item_removed(item_name: String, new_count: int)
signal tool_equipped(tool_name: String)

var items         : Dictionary = {}
var equipped_tool : String     = ""

func add_item(item_name: String, amount: int = 1) -> void:
	if items.has(item_name):
		items[item_name] += amount
	else:
		items[item_name] = amount
	emit_signal("item_added", item_name, items[item_name])

func remove_item(item_name: String, amount: int = 1) -> bool:
	if not has_item(item_name, amount):
		return false
	items[item_name] -= amount
	if items[item_name] <= 0:
		items.erase(item_name)
	emit_signal("item_removed", item_name, items.get(item_name, 0))
	return true

func has_item(item_name: String, amount: int = 1) -> bool:
	return items.get(item_name, 0) >= amount

func count(item_name: String) -> int:
	return items.get(item_name, 0)

func equip_tool(tool_name: String) -> void:
	if not has_item(tool_name):
		push_warning("Inventory: Cannot equip %s" % tool_name)
		return
	equipped_tool = tool_name
	emit_signal("tool_equipped", tool_name)

func use_equipped_tool(target: Node) -> void:
	if equipped_tool == "":
		return
	if target.has_method("on_tool_used"):
		target.on_tool_used(equipped_tool)

func debug_print() -> void:
	print("── Inventory ──")
	for key in items:
		print("  %s: %d" % [key, items[key]])
	print("  Equipped: %s" % equipped_tool)
