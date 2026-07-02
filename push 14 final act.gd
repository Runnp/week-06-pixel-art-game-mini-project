# PUSH 14 — Final Act: TNT + Water Rise + Ending
# Commit: "Push 14: TNT mechanic, water rise effect, sunset ending trigger"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/world/north_wall.gd
# The wall between Uzbekistan and Kazakhstan — blow it up with TNT
# Attach to: StaticBody2D "NorthWall" in Border.tscn
# ════════════════════════════════════════════════════════════════

extends StaticBody2D

var _blown : bool = false


func interact() -> void:
	if _blown:
		return

	if not Inventory.has_item("tnt"):
		DialogueManager.start([
			{ "speaker": "Rustam",       "text": "This barrier is too thick. I need explosives." },
			{ "speaker": "Guard (KZ)",   "text": "We have TNT in the supply depot. Take it, friend." }
		])
		return

	DialogueManager.start([
		{ "speaker": "",             "text": "[Rustam and the Kazakh guard look at each other]" },
		{ "speaker": "Guard (KZ)",   "text": "Are you sure about this? Once it goes..." },
		{ "speaker": "Rustam",       "text": "The water does not care about borders. And neither do I." },
		{ "speaker": "Guard (KZ)",   "text": "...Then we do it together." },
		{ "speaker": "",             "text": "[Both sides step back. Rustam plants the TNT.]" }
	])

	await DialogueManager.dialogue_ended
	Inventory.remove_item("tnt")
	_detonate()


func _detonate() -> void:
	_blown = true

	# Screen shake
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera2D"):
		var cam   := player.get_node("Camera2D")
		var tween := create_tween()
		for i in 8:
			tween.tween_property(cam, "offset",
				Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.05)
		tween.tween_property(cam, "offset", Vector2.ZERO, 0.1)

	# White flash
	var flash         := ColorRect.new()
	flash.color        = Color(1, 1, 1, 0.9)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	get_tree().current_scene.add_child(flash)

	await get_tree().create_timer(0.2).timeout

	var tween2 := create_tween()
	tween2.tween_property(flash, "color:a", 0.0, 1.0)
	await tween2.finished
	flash.queue_free()

	# Wall crumbles
	var wall_tween := create_tween()
	wall_tween.tween_property(self, "modulate:a", 0.0, 0.8)
	await wall_tween.finished
	queue_free()

	# Trigger water rise
	var water := get_tree().get_first_node_in_group("rising_water")
	if water:
		water.start_rising()


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/world/rising_water.gd
# Attach to: ColorRect or Sprite2D group "rising_water"
# Start it offscreen at the bottom — rises up slowly
# ════════════════════════════════════════════════════════════════

extends Node2D

const RISE_DURATION := 8.0   # seconds for water to fill
var _rising : bool = false


func _ready() -> void:
	add_to_group("rising_water")
	modulate.a = 0.0   # invisible until triggered


func start_rising() -> void:
	if _rising:
		return
	_rising = true

	# Fade water in
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.7, 1.5)

	# Move water upward (simulates filling)
	var rise_tween := create_tween()
	rise_tween.tween_property(
		self, "position",
		position + Vector2(0, -200),
		RISE_DURATION
	)

	await rise_tween.finished
	_trigger_ending()


func _trigger_ending() -> void:
	DialogueManager.start([
		{ "speaker": "",       "text": "[The water rushes in from the north — cold and real]" },
		{ "speaker": "Rustam", "text": "It is happening. It is actually happening." },
		{ "speaker": "",       "text": "[Fish swim past him. The sky turns orange.]" },
		{ "speaker": "Rustam", "text": "Grandmother... I kept the promise." },
		{ "speaker": "",       "text": "[Rustam swims toward the sunset — the Aral Sea lives again]" }
	])

	await DialogueManager.dialogue_ended
	await get_tree().create_timer(2.0).timeout

	# Go to credits / main menu
	GameManager.change_scene("res://scenes/ui/Credits.tscn")
