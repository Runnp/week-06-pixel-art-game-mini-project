extends Node

var _running : bool = false


func play(steps: Array) -> void:
	if _running:
		return
	_running = true
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
	await _execute_steps(steps)
	if player:
		player.can_move = true
	_running = false


func _execute_steps(steps: Array) -> void:
	for step in steps:
		await _execute_step(step)


func _execute_step(step: Dictionary) -> void:
	match step.get("type", ""):

		"dialogue":
			DialogueManager.start(step.get("lines", []))
			await DialogueManager.dialogue_ended

		"fade_out":
			await ScreenFade.fade_out(step.get("duration", 0.5))

		"fade_in":
			await ScreenFade.fade_in(step.get("duration", 0.5))

		"flash":
			var col := step.get("color", Color.WHITE)
			await ScreenFade.flash(col, step.get("duration", 0.3))

		"wait":
			await get_tree().create_timer(step.get("duration", 1.0)).timeout

		"letterbox_in":
			await CinematicCamera.letterbox_in(step.get("duration", 0.5))

		"letterbox_out":
			await CinematicCamera.letterbox_out(step.get("duration", 0.5))

		"zoom_in":
			await CinematicCamera.zoom_in(
				step.get("zoom", 1.8),
				step.get("duration", 1.0)
			)

		"zoom_out":
			await CinematicCamera.zoom_out(step.get("duration", 1.0))

		"shake":
			await CinematicCamera.shake(
				step.get("strength", 4.0),
				step.get("duration", 0.4)
			)

		"pan_to":
			await CinematicCamera.pan_to(
				step.get("position", Vector2.ZERO),
				step.get("hold", 2.0),
				step.get("duration", 1.0)
			)

		"move_node":
			var node := get_tree().get_first_node_in_group(
				step.get("group", "")
			)
			if node:
				var tween := create_tween()
				tween.tween_property(
					node, "global_position",
					step.get("to", node.global_position),
					step.get("duration", 1.0)
				)
				await tween.finished

		"play_anim":
			var node := get_tree().get_first_node_in_group(
				step.get("group", "")
			)
			if node and node.has_node("AnimatedSprite2D"):
				node.get_node("AnimatedSprite2D").play(
					step.get("anim", "idle_down")
				)

		"show_node":
			var node := get_tree().get_first_node_in_group(
				step.get("group", "")
			)
			if node:
				node.visible = step.get("visible", true)

		"change_scene":
			await ScreenFade.fade_out(0.5)
			GameManager.change_scene(step.get("scene", ""))

		"sound":
			# Placeholder — connect to AudioManager when audio added
			pass

		_:
			push_warning("CutscenePlayer: Unknown step type: %s" % step.get("type"))


# ═══════════════════════════════════════════════════════════════
# PREDEFINED CUTSCENES — call these from level scripts
# ═══════════════════════════════════════════════════════════════

func play_jeep_travel() -> void:
	await play([
		{ "type": "letterbox_in",  "duration": 0.5 },
		{ "type": "dialogue", "lines": [
			{ "speaker": "",       "text": "[Malik's jeep. The road to Muynak stretches ahead.]" },
			{ "speaker": "Malik",  "text": "You know what I hate most about this desert?" },
			{ "speaker": "Rustam", "text": "The dust?" },
			{ "speaker": "Malik",  "text": "No. That I remember when it was not desert." },
			{ "speaker": "",       "text": "[The ship graveyard appears on the horizon.]" },
			{ "speaker": "Rustam", "text": "...I see them. The ships." },
			{ "speaker": "Malik",  "text": "Every time. Still gets me every time." },
		]},
		{ "type": "wait",          "duration": 1.5 },
		{ "type": "fade_out",      "duration": 1.0 },
		{ "type": "letterbox_out", "duration": 0.1 },
		{ "type": "change_scene",  "scene": "res://scenes/levels/Muynak.tscn" },
	])


func play_well_activation() -> void:
	await play([
		{ "type": "letterbox_in",  "duration": 0.8 },
		{ "type": "zoom_in",       "zoom": 1.8, "duration": 1.5 },
		{ "type": "dialogue", "lines": [
			{ "speaker": "",       "text": "[The well rumbles. Something ancient stirs below.]" },
			{ "speaker": "Rustam", "text": "My blood. For the sea." },
			{ "speaker": "",       "text": "[He opens his palm. Lets it fall into the dark.]" },
		]},
		{ "type": "flash",         "color": Color(0.6, 0.0, 0.0), "duration": 0.6 },
		{ "type": "wait",          "duration": 0.8 },
		{ "type": "flash",         "color": Color.WHITE, "duration": 0.4 },
		{ "type": "dialogue", "lines": [
			{ "speaker": "",       "text": "[Water erupts from the well. Cold and real.]" },
			{ "speaker": "",       "text": "[Rustam is thrown back. Then lifted.]" },
			{ "speaker": "",       "text": "[He feels completely new.]" },
		]},
		{ "type": "zoom_out",      "duration": 1.0 },
		{ "type": "letterbox_out", "duration": 0.5 },
	])


func play_tnt_explosion(wall_pos: Vector2) -> void:
	await play([
		{ "type": "letterbox_in",  "duration": 0.3 },
		{ "type": "dialogue", "lines": [
			{ "speaker": "",            "text": "[Both men step back. The fuse is lit.]" },
			{ "speaker": "Guard (KZ)", "text": "Cover your ears." },
		]},
		{ "type": "wait",          "duration": 2.0 },
		{ "type": "shake",         "strength": 7.0, "duration": 0.6 },
		{ "type": "flash",         "color": Color.WHITE, "duration": 0.25 },
		{ "type": "pan_to",        "position": wall_pos, "hold": 3.0, "duration": 1.0 },
		{ "type": "dialogue", "lines": [
			{ "speaker": "",            "text": "[Dust settles. The wall is gone.]" },
			{ "speaker": "",            "text": "[Water begins flowing through the gap.]" },
			{ "speaker": "Guard (KZ)", "text": "It is working." },
			{ "speaker": "Rustam",     "text": "It is working." },
		]},
		{ "type": "letterbox_out", "duration": 0.8 },
	])


func play_ending_swim() -> void:
	await play([
		{ "type": "letterbox_in",  "duration": 1.0 },
		{ "type": "zoom_in",       "zoom": 1.5, "duration": 3.0 },
		{ "type": "dialogue", "lines": [
			{ "speaker": "",       "text": "[The Aral Sea. Returned.]" },
			{ "speaker": "",       "text": "[Not all of it. Not yet. But enough.]" },
			{ "speaker": "Rustam", "text": "Grandmother." },
			{ "speaker": "Rustam", "text": "I kept the promise." },
			{ "speaker": "",       "text": "[He swims toward the orange horizon.]" },
			{ "speaker": "",       "text": "[The water is cold. And clean. And alive.]" },
		]},
		{ "type": "wait",         "duration": 4.0 },
		{ "type": "fade_out",     "duration": 3.0 },
		{ "type": "change_scene", "scene": "res://scenes/ui/Credits.tscn" },
	])
