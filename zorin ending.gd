# PUSH 25 — Minister Zorin + Evidence System + Both Endings
# Commit: "Push 25: Zorin NPC, evidence presentation, good/bad endings"
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/npcs/npc_zorin.gd
# LOCATION: res://scripts/npcs/npc_zorin.gd
# Attach to: StaticBody2D "Zorin" in Room 14 of USSR.tscn
# This is the most important NPC in the game.
# ════════════════════════════════════════════════════════════════

extends "res://scripts/npcs/npc_base.gd"

var _evidence_presented : Array = []
var _convinced          : bool  = false
var _door_blocked       : bool  = true   # secretary blocks until all evidence found

@onready var secretary_blocker : StaticBody2D = $SecretaryBlocker


func _on_ready_override() -> void:
	waypoints        = []     # Zorin never leaves his desk
	move_speed       = 0.0
	wait_at_waypoint = 999.0


func _on_interact() -> void:
	if _convinced:
		DialogueManager.start([
			{ "speaker": "Zorin", "text": "I added the footnote. That is all I could do." },
			{ "speaker": "Zorin", "text": "I hope it is enough, young man." }
		])
		return

	var has_report   := Inventory.has_item("report")
	var has_photo    := Inventory.has_item("photograph")
	var has_letter   := Inventory.has_item("letter")
	var total        := (1 if has_report else 0) + \
						(1 if has_photo  else 0) + \
						(1 if has_letter else 0)

	if total == 0:
		DialogueManager.start([
			{ "speaker": "Zorin", "text": "I am busy. The signing ceremony is in one hour." },
			{ "speaker": "Zorin", "text": "Whatever you want — come back another time." }
		])
		return

	# Present evidence one by one in correct order
	await _present_evidence(has_report, has_photo, has_letter)


func _present_evidence(has_report: bool, has_photo: bool, has_letter: bool) -> void:
	DialogueManager.start([
		{ "speaker": "Zorin", "text": "You again. What is it?" },
		{ "speaker": "Rustam","text": "Minister Zorin. I need five minutes." },
		{ "speaker": "Zorin", "text": "You have three." }
	])
	await DialogueManager.dialogue_ended

	# Present each item found
	if has_report and not "report" in _evidence_presented:
		_evidence_presented.append("report")
		Inventory.remove_item("report")
		DialogueManager.start([
			{ "speaker": "Rustam","text": "This report. Your own hydrologists wrote it in 1948." },
			{ "speaker": "Rustam","text": "They predicted the sea would lose half its volume by 1990." },
			{ "speaker": "Zorin", "text": "That is one scientist's opinion." },
			{ "speaker": "Rustam","text": "It is a prediction. And it came true." },
			{ "speaker": "Zorin", "text": "..." }
		])
		await DialogueManager.dialogue_ended

	if has_photo and not "photograph" in _evidence_presented:
		_evidence_presented.append("photograph")
		Inventory.remove_item("photograph")
		DialogueManager.start([
			{ "speaker": "Rustam","text": "This photograph. The Aral Sea. Today." },
			{ "speaker": "Zorin", "text": "That cannot be the same sea." },
			{ "speaker": "Rustam","text": "In seventy years — nothing but dust and salt." },
			{ "speaker": "Rustam","text": "Children cannot breathe. The fish are gone." },
			{ "speaker": "Zorin", "text": "Where did you get this photograph?" },
			{ "speaker": "Rustam","text": "I took it. Where I come from." },
			{ "speaker": "Zorin", "text": "...Where do you come from?" }
		])
		await DialogueManager.dialogue_ended

	if has_letter and not "letter" in _evidence_presented:
		_evidence_presented.append("letter")
		Inventory.remove_item("letter")
		DialogueManager.start([
			{ "speaker": "Rustam","text": "A letter. From a Karakalpak fisherman." },
			{ "speaker": "Rustam","text": "He writes to his son about the water. The fish. The life here." },
			{ "speaker": "Zorin", "text": "...This fisherman. He has children?" },
			{ "speaker": "Rustam","text": "His grandchildren cannot breathe clean air." },
			{ "speaker": "Rustam","text": "His great-grandchildren will never see the sea." },
			{ "speaker": "",      "text": "[Long silence. Zorin looks at the river map. Then at Rustam.]" },
			{ "speaker": "Zorin", "text": "How do you know all this?" },
			{ "speaker": "Rustam","text": "I lived it." },
			{ "speaker": "",      "text": "[Zorin sets down his pen.]" }
		])
		await DialogueManager.dialogue_ended
		_zorin_considers()


func _zorin_considers() -> void:
	DialogueManager.start([
		{ "speaker": "Zorin", "text": "I cannot stop the project. The order comes from Moscow." },
		{ "speaker": "Zorin", "text": "Cotton production is a national priority." },
		{ "speaker": "Rustam","text": "I am not asking you to stop it." },
		{ "speaker": "Rustam","text": "Just add a footnote. Minimum water flow to the sea." },
		{ "speaker": "Rustam","text": "One sentence. That is all." },
		{ "speaker": "Zorin", "text": "A footnote." },
		{ "speaker": "Rustam","text": "A footnote saved the North Aral Sea in 2005." },
		{ "speaker": "Rustam","text": "A footnote is enough." },
		{ "speaker": "",      "text": "[Zorin opens the order document. Picks up his pen.]" },
		{ "speaker": "",      "text": "[He writes for a long moment.]" },
		{ "speaker": "Zorin", "text": "There. Clause 7, sub-paragraph C." },
		{ "speaker": "Zorin", "text": "Minimum ecological flow. Non-negotiable." },
		{ "speaker": "Zorin", "text": "That is all I can do." },
		{ "speaker": "Rustam","text": "That is everything." }
	])

	await DialogueManager.dialogue_ended
	_convinced = true
	anim.play("idle_stand")

	# Notify level controller
	var level := get_tree().get_first_node_in_group("ussr_level")
	if level and level.has_method("on_zorin_convinced"):
		level.on_zorin_convinced()


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/levels/ending_controller.gd
# LOCATION: res://scripts/levels/ending_controller.gd
# Attach to: root Node2D of Border.tscn
# Handles both ending branches depending on zorin_convinced flag
# ════════════════════════════════════════════════════════════════

extends Node2D

func _ready() -> void:
	await ScreenFade.fade_in(1.0)

	if GameManager.time_travel_taken and GameManager.zorin_convinced:
		_good_ending_intro()
	elif GameManager.time_travel_taken and not GameManager.zorin_convinced:
		_bittersweet_ending_intro()
	else:
		_original_ending_intro()


func _good_ending_intro() -> void:
	DialogueManager.start([
		{ "speaker": "",       "text": "[You are back. The border wall stands before you.]" },
		{ "speaker": "Rustam", "text": "I planted a seed in 1953." },
		{ "speaker": "Rustam", "text": "Seventy years ago. One footnote." },
		{ "speaker": "Rustam", "text": "Now I finish what it started." },
		{ "speaker": "",       "text": "[Find the Kazakh guard. The TNT is waiting.]" }
	])


func _bittersweet_ending_intro() -> void:
	DialogueManager.start([
		{ "speaker": "",       "text": "[You are back. Zorin signed before you reached him.]" },
		{ "speaker": "Rustam", "text": "I was too slow. The past would not wait." },
		{ "speaker": "Rustam", "text": "But I am here. The present still can be changed." },
		{ "speaker": "",       "text": "[Find the Kazakh guard. There is still work to do.]" }
	])


func _original_ending_intro() -> void:
	DialogueManager.start([
		{ "speaker": "",       "text": "[The border wall. Kazakhstan on the other side.]" },
		{ "speaker": "Rustam", "text": "The past is done. This is what I can change." },
		{ "speaker": "",       "text": "[Find the Kazakh guard.]" }
	])


# ════════════════════════════════════════════════════════════════
# ADD TO game_manager.gd — two new variables:
# (open game_manager.gd and add these lines after well_activated)
# ════════════════════════════════════════════════════════════════
#
# var time_travel_taken : bool = false
# var zorin_convinced   : bool = false
#
# These drive which ending dialogue plays in ending_controller.gd


# ════════════════════════════════════════════════════════════════
# FINAL ENDING TEXT (shown after water rises — edit rising_water.gd)
# Replace _trigger_ending() dialogue in rising_water.gd with:
# ════════════════════════════════════════════════════════════════
#
# func _trigger_ending() -> void:
#     var good := GameManager.zorin_convinced
#
#     if good:
#         DialogueManager.start([
#             { "speaker": "",       "text": "[The water rushes in. From the north AND the south.]" },
#             { "speaker": "Rustam", "text": "Zorin's footnote. Seventy years later." },
#             { "speaker": "Rustam", "text": "It held." },
#             { "speaker": "",       "text": "[Fish swim past. The sky turns orange.]" },
#             { "speaker": "Rustam", "text": "Grandmother... I kept the promise." },
#             { "speaker": "",       "text": "[Bibi stands on the shore. Young. Waving.]" },
#             { "speaker": "",       "text": "[Rustam swims toward the sunset.]" }
#         ])
#     else:
#         DialogueManager.start([
#             { "speaker": "",       "text": "[The water rises. Slowly. From the north only.]" },
#             { "speaker": "Rustam", "text": "It is enough. It has to be enough." },
#             { "speaker": "",       "text": "[Fish swim past. The sea breathes again.]" },
#             { "speaker": "",       "text": "[Some changes come too late to prevent.]" },
#             { "speaker": "",       "text": "[But never too late to begin healing.]" }
#         ])
#
#     await DialogueManager.dialogue_ended
#     await get_tree().create_timer(2.0).timeout
#     GameManager.change_scene("res://scenes/ui/Credits.tscn")
