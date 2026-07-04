# PUSH 10 — Restoration Mechanics
# Commit: "Push 10: Tree planting, soil spray, ship scrap interactables"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/world/soil_patch.gd
# Attach to: Area2D nodes placed on the dry seabed tiles
# ════════════════════════════════════════════════════════════════

extends Area2D

var _sprayed : bool = false


func interact() -> void:
	if _sprayed:
		DialogueManager.start([
			{ "speaker": "", "text": "[Already treated this patch]" }
		])
		return

	if not Inventory.has_item("spray_can"):
		DialogueManager.start([
			{ "speaker": "Rustam", "text": "I need a spray can to treat this soil." }
		])
		return

	_sprayed = true
	_play_spray_effect()
	GameManager.plant_tree()   # counts toward restoration progress


func _play_spray_effect() -> void:
	# Simple color shift to show treated soil
	modulate = Color(0.4, 0.8, 0.3)   # green tint
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.0)
	print("[SoilPatch] Soil treated! Trees: ", GameManager.trees_planted)


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/world/tree_spot.gd
# Attach to: Area2D nodes — spots where trees can be planted
# ════════════════════════════════════════════════════════════════

extends Area2D

@onready var sprite : Sprite2D = $Sprite2D  # shows empty hole, then sapling, then tree

var _stage : int = 0   # 0=empty  1=sapling  2=grown


func interact() -> void:
	match _stage:
		0:
			if not Inventory.has_item("tree_sapling"):
				DialogueManager.start([
					{ "speaker": "Rustam", "text": "I need a sapling to plant here." }
				])
				return
			Inventory.remove_item("tree_sapling")
			_stage = 1
			_update_visual()
			DialogueManager.start([
				{ "speaker": "Rustam", "text": "There. One small tree against the dust." }
			])
			GameManager.plant_tree()

		1:
			DialogueManager.start([
				{ "speaker": "", "text": "[The sapling needs time to grow...]" }
			])

		2:
			DialogueManager.start([
				{ "speaker": "Rustam", "text": "It is growing. This is good." }
			])


func _update_visual() -> void:
	# Swap sprite frame: 0=hole, 1=sapling, 2=tree
	if sprite:
		sprite.frame = _stage


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/world/ship_wreck.gd
# Attach to: StaticBody2D ships in Muynak level (Chapter 2)
# ════════════════════════════════════════════════════════════════

extends StaticBody2D

@export var parts_remaining : int = 3   # hit 3 times to fully scrap
var _scrapped : bool = false


func interact() -> void:
	if _scrapped:
		DialogueManager.start([
			{ "speaker": "", "text": "[Nothing more to salvage here]" }
		])
		return

	if Inventory.equipped_tool != "bolgarka":
		DialogueManager.start([
			{ "speaker": "Rustam", "text": "I need the angle grinder (bolgarka) for this." }
		])
		return

	parts_remaining -= 1
	_play_cut_effect()
	Inventory.add_item("ship_part", 1)

	if parts_remaining <= 0:
		_scrapped = true
		GameManager.scrap_ship()
		DialogueManager.start([
			{ "speaker": "Rustam", "text": "Done. The metal will be useful." }
		])
		# Fade out the ship wreck
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.5)
		await tween.finished
		queue_free()


func _play_cut_effect() -> void:
	# Quick shake effect to feel like grinding
	var origin := position
	var tween  := create_tween()
	tween.tween_property(self, "position", origin + Vector2(2, 0), 0.05)
	tween.tween_property(self, "position", origin - Vector2(2, 0), 0.05)
	tween.tween_property(self, "position", origin, 0.05)
