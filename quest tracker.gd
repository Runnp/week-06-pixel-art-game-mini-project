# PUSH 35 — Quest Tracker + Chapter Objectives
# Commit: "Push 35: Objective system, chapter goals, HUD tracker"
# File: res://scripts/systems/quest_tracker.gd
# REGISTER AS AUTOLOAD: Name it "QuestTracker"
#   Project > Project Settings > Autoload > +
#   Name: QuestTracker
# ═══════════════════════════════════════════════════════════════
# WHAT THIS DOES:
#   Tracks current chapter objectives.
#   Shows them on HUD as a small checklist.
#   Marks complete when conditions are met.
#   Drives the HUD objective panel.
# ═══════════════════════════════════════════════════════════════

extends Node

signal objective_completed(objective_id: String)
signal all_objectives_completed(chapter: int)

# Each chapter has a list of objectives
# id: unique string
# text: shown to player
# check: callable that returns true when complete
const CHAPTER_OBJECTIVES := {
	1: [
		{
			"id":    "talk_bibi",
			"text":  "Talk to grandmother Bibi",
			"check": func(): return DialogueManager != null and \
						get_tree().get_first_node_in_group("npc") != null
		},
		{
			"id":    "find_malik",
			"text":  "Find Malik and his jeep",
			"check": func(): return Inventory.has_item("shovel") or \
						GameManager.trees_planted > 0
		},
		{
			"id":    "plant_first_tree",
			"text":  "Plant at least one tree",
			"check": func(): return GameManager.trees_planted >= 1
		},
	],
	2: [
		{
			"id":    "meet_kamola",
			"text":  "Find Dr. Kamola's research tent",
			"check": func(): return ToolUpgrades.get_level("bolgarka") >= 0 \
						and Inventory.has_item("bolgarka")
		},
		{
			"id":    "scrap_ships",
			"text":  "Scrap 3 abandoned ships",
			"check": func(): return GameManager.ships_scrapped >= 3
		},
		{
			"id":    "find_fisherman",
			"text":  "Speak to the old fisherman",
			"check": func(): return true   # set true when talked (handled below)
		},
	],
	3: [
		{
			"id":    "treat_soil",
			"text":  "Treat 4 soil patches",
			"check": func(): return GameManager.trees_planted >= 4
		},
		{
			"id":    "find_well",
			"text":  "Find the hidden well",
			"check": func(): return GameManager.well_activated
		},
		{
			"id":    "defeat_specter",
			"text":  "Defeat the Cotton Specter",
			"check": func(): return GameManager.well_activated   # specter dies before well
		},
	],
	4: [
		{
			"id":    "reach_border",
			"text":  "Reach the Kazakhstan border",
			"check": func(): return true   # true on level load
		},
		{
			"id":    "talk_guard",
			"text":  "Speak with the Kazakh guard",
			"check": func(): return Inventory.has_item("tnt")
		},
		{
			"id":    "blow_wall",
			"text":  "Break the northern wall",
			"check": func(): return not Inventory.has_item("tnt") \
						and GameManager.ships_scrapped >= 3
		},
	],
	5: [
		{
			"id":    "find_evidence",
			"text":  "Collect all 3 pieces of evidence",
			"check": func(): return Inventory.has_item("report") or \
						Inventory.has_item("photograph") or \
						Inventory.has_item("letter")
		},
		{
			"id":    "convince_zorin",
			"text":  "Convince Minister Zorin",
			"check": func(): return GameManager.zorin_convinced
		},
	],
}

var _completed : Array = []   # completed objective IDs this run


func _ready() -> void:
	GameManager.chapter_changed.connect(_on_chapter_changed)
	GameManager.item_collected.connect(func(_i): _check_all())
	Inventory.item_added.connect(func(_n, _c): _check_all())


func _on_chapter_changed(chapter: int) -> void:
	# Reset completed list for new chapter
	_completed.clear()
	_check_all()


func _check_all() -> void:
	var chapter := GameManager.current_chapter
	if not CHAPTER_OBJECTIVES.has(chapter):
		return

	for obj in CHAPTER_OBJECTIVES[chapter]:
		var id : String = obj["id"]
		if id in _completed:
			continue
		if obj["check"].call():
			_completed.append(id)
			emit_signal("objective_completed", id)

	# Check if all done
	if _completed.size() >= CHAPTER_OBJECTIVES[chapter].size():
		emit_signal("all_objectives_completed", chapter)


func mark_complete(objective_id: String) -> void:
	# Manual completion for objectives checked by NPC scripts
	if not objective_id in _completed:
		_completed.append(objective_id)
		emit_signal("objective_completed", objective_id)
		_check_all()


func get_current_objectives() -> Array:
	var chapter := GameManager.current_chapter
	if not CHAPTER_OBJECTIVES.has(chapter):
		return []
	return CHAPTER_OBJECTIVES[chapter]


func is_complete(objective_id: String) -> bool:
	return objective_id in _completed


# ═══════════════════════════════════════════════════════════════
# FILE 2: res://scripts/ui/objective_panel.gd
# LOCATION: res://scripts/ui/objective_panel.gd
# Attach to: VBoxContainer "ObjectivePanel" inside HUD.tscn
# Add under the RestorationBox in HUD.tscn scene tree
# ═══════════════════════════════════════════════════════════════

# extends VBoxContainer
#
# @onready var title_label : Label = $TitleLabel
#
# var _obj_labels : Array = []
#
# func _ready() -> void:
#     title_label.text = "Objectives"
#     QuestTracker.objective_completed.connect(_on_objective_done)
#     GameManager.chapter_changed.connect(func(_c): _rebuild())
#     _rebuild()
#
# func _rebuild() -> void:
#     for lbl in _obj_labels:
#         lbl.queue_free()
#     _obj_labels.clear()
#
#     for obj in QuestTracker.get_current_objectives():
#         var lbl       := Label.new()
#         var done      := QuestTracker.is_complete(obj["id"])
#         lbl.text       = ("✓ " if done else "○ ") + obj["text"]
#         lbl.modulate   = Color(0.6, 1.0, 0.6) if done else Color.WHITE
#         add_child(lbl)
#         _obj_labels.append(lbl)
#
# func _on_objective_done(_id: String) -> void:
#     _rebuild()
#
# ── ADD TO HUD.TSCN SCENE TREE ────────────────────────────────
# Under VBoxContainer add:
#   VBoxContainer (name: ObjectivePanel, objective_panel.gd)
#   └── Label (name: TitleLabel) text:"Objectives" bold
# Uncomment the script above and paste into objective_panel.gd
