# PUSH 19 — NPC Kamola + Tool Upgrade System
# Commit: "Push 19: Kamola NPC, tool upgrades, research tent interaction"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/npcs/npc_kamola.gd
# LOCATION: res://scripts/npcs/npc_kamola.gd
# Attach to: StaticBody2D root of Kamola.tscn
# Place her inside a research tent in Muynak level
# ════════════════════════════════════════════════════════════════

extends StaticBody2D

@export var dialogue_file : String = "res://data/dialogue/kamola.json"

var _met_before      : bool = false
var _upgrade_offered : bool = false


func interact() -> void:
	if not _met_before:
		_met_before = true
		DialogueManager.start_from_file(dialogue_file)
		await DialogueManager.dialogue_ended
		_offer_upgrades()
		return

	_offer_upgrades()


func _offer_upgrades() -> void:
	var ship_parts := Inventory.count("ship_part")

	if ship_parts >= 3 and not _upgrade_offered:
		_upgrade_offered = true
		DialogueManager.start([
			{ "speaker": "Kamola", "text": "You have enough ship parts. I can upgrade your tools." },
			{ "speaker": "Kamola", "text": "Give me the parts — I will reinforce your bolgarka." },
			{ "speaker": "Rustam", "text": "Do it. Every second counts." }
		])
		await DialogueManager.dialogue_ended
		ToolUpgrades.upgrade("bolgarka")
		Inventory.remove_item("ship_part", 3)
	else:
		var remaining := max(0, 3 - ship_parts)
		DialogueManager.start([
			{ "speaker": "Kamola", "text": "Bring me %d more ship parts and I can upgrade your tools." % remaining },
			{ "speaker": "Kamola", "text": "The metal from those wrecks is still good for something." }
		])


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/systems/tool_upgrades.gd
# LOCATION: res://scripts/systems/tool_upgrades.gd
# REGISTER AS AUTOLOAD: Name it "ToolUpgrades"
#   Project > Project Settings > Autoload > +
#   Name: ToolUpgrades
# ════════════════════════════════════════════════════════════════

extends Node

signal tool_upgraded(tool_name: String, level: int)

# Tracks upgrade level per tool (max level 2)
var _levels : Dictionary = {
	"shovel":    0,
	"rake":      0,
	"spray_can": 0,
	"bolgarka":  0,
}

# What each upgrade level does (applied in gameplay scripts)
const UPGRADE_EFFECTS := {
	"bolgarka": {
		1: "Scraps ships in 2 hits instead of 3",
		2: "One-hit scraps + drops extra ship_part"
	},
	"shovel": {
		1: "Dig animation 50% faster",
		2: "Chance to find buried diary pages"
	},
	"spray_can": {
		1: "Treats 2 soil patches per use",
		2: "Permanent area spray — no aim needed"
	},
	"rake": {
		1: "Clears salt crust in 1 hit",
		2: "Passive — clears small salt patches on walk"
	},
}


func upgrade(tool_name: String) -> void:
	if not _levels.has(tool_name):
		push_warning("ToolUpgrades: Unknown tool %s" % tool_name)
		return

	var current := _levels[tool_name]
	if current >= 2:
		DialogueManager.start([
			{ "speaker": "Kamola", "text": "This tool is already at maximum upgrade." }
		])
		return

	_levels[tool_name] = current + 1
	var new_level      := _levels[tool_name]
	emit_signal("tool_upgraded", tool_name, new_level)

	var effect := UPGRADE_EFFECTS.get(tool_name, {}).get(new_level, "Improved")
	DialogueManager.start([
		{ "speaker": "Kamola", "text": "Done. %s upgraded to level %d." % [tool_name.capitalize(), new_level] },
		{ "speaker": "",       "text": "[%s]" % effect }
	])


func get_level(tool_name: String) -> int:
	return _levels.get(tool_name, 0)


func is_upgraded(tool_name: String) -> bool:
	return _levels.get(tool_name, 0) > 0


# ════════════════════════════════════════════════════════════════
# KAMOLA DIALOGUE JSON
# LOCATION: res://data/dialogue/kamola.json
# ════════════════════════════════════════════════════════════════
#
# Save this as kamola.json in res://data/dialogue/:
#
# [
#   { "speaker": "Kamola", "text": "You must be Rustam. I heard about you from the UN office." },
#   { "speaker": "Rustam", "text": "Dr. Kamola. I read your paper on soil remediation." },
#   { "speaker": "Kamola", "text": "Then you know how bad it is. The salt concentration is toxic." },
#   { "speaker": "Kamola", "text": "I have been out here three months. My team went home. I stayed." },
#   { "speaker": "Rustam", "text": "Why?" },
#   { "speaker": "Kamola", "text": "Because someone has to count what is being lost. And I am good at math." },
#   { "speaker": "",       "text": "[Kamola hands Rustam a chemical spray canister]" },
#   { "speaker": "Kamola", "text": "This treats the salt crust. Use it on the exposed seabed patches." },
#   { "speaker": "Kamola", "text": "And bring me ship parts if you find them. I can improve your tools." }
# ]
#
# ── SCENE STRUCTURE FOR Kamola.tscn ──────────────────────────
# StaticBody2D  (name: Kamola, npc_kamola.gd)
# ├── AnimatedSprite2D
# │     Animations: idle (2 frames), speak (2 frames)
# ├── CollisionShape2D  RectangleShape2D  16x24
# └── (add to Muynak.tscn inside a tent Area2D)
