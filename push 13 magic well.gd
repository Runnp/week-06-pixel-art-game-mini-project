# PUSH 13 — Magic Well + Blood Sacrifice Cutscene
# File: res://scripts/world/magic_well.gd
# Commit: "Push 13: Magic well, blood sacrifice trigger, player rebirth"
# Attach to: Area2D or StaticBody2D placed at well location in Seafloor.tscn

extends StaticBody2D

var _activated : bool = false


func interact() -> void:
	if _activated:
		DialogueManager.start([
			{ "speaker": "", "text": "[The well pulses with new life. You feel its power still.]" }
		])
		return

	# Check player has done enough restoration to unlock well
	if GameManager.trees_planted < 2 or GameManager.ships_scrapped < 2:
		DialogueManager.start([
			{ "speaker": "",       "text": "[The well is dry. Something is missing...]" },
			{ "speaker": "Rustam", "text": "The land is not ready yet. I must do more." }
		])
		return

	_activate_well()


func _activate_well() -> void:
	_activated = true

	# Phase 1 — Rustam discovers the well
	DialogueManager.start([
		{ "speaker": "",       "text": "[A hidden well. The locals said it was just a legend...]" },
		{ "speaker": "Rustam", "text": "The old stories were true. This well runs deep." },
		{ "speaker": "",       "text": "[An inscription reads: Only a willing sacrifice can wake the water]" },
		{ "speaker": "Rustam", "text": "My blood... for the sea?" },
		{ "speaker": "Rustam", "text": "...Yes. If that is what it takes." }
	])

	await DialogueManager.dialogue_ended

	# Phase 2 — Screen flash, rebirth
	await _play_sacrifice_effect()

	# Phase 3 — Player is reborn
	DialogueManager.start([
		{ "speaker": "",       "text": "[The dry well erupts — water surges upward]" },
		{ "speaker": "",       "text": "[Rustam feels the cold water fill his lungs, then air again]" },
		{ "speaker": "Rustam", "text": "I can breathe. I feel... new." },
		{ "speaker": "",       "text": "[Rustam is reborn. Health fully restored. Speed increased.]" }
	])

	await DialogueManager.dialogue_ended

	# Heal and buff the player
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.health = player.MAX_HEALTH
		player.SPEED  = 110.0   # permanently faster after rebirth
		GameManager.emit_signal("player_health_changed", player.MAX_HEALTH)

	GameManager.activate_well()


func _play_sacrifice_effect() -> Signal:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

	# Red flash — blood
	var overlay := ColorRect.new()
	overlay.color        = Color(0.6, 0.0, 0.0, 0.0)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	get_tree().current_scene.add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.8, 0.5)
	tween.tween_property(overlay, "color:a", 0.0, 1.2)

	await tween.finished

	# White flash — rebirth
	overlay.color = Color(1, 1, 1, 0.0)
	var tween2 := create_tween()
	tween2.tween_property(overlay, "color:a", 1.0, 0.3)
	tween2.tween_property(overlay, "color:a", 0.0, 1.0)

	await tween2.finished
	overlay.queue_free()

	if player:
		player.can_move = true

	return tween2.finished
