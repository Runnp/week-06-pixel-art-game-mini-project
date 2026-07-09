# PUSH 22 — All Remaining NPC Scripts
# Commit: "Push 22: Malik, Kazakh guard, old fisherman NPCs"
# All extend npc_base.gd from today's session
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/npcs/npc_bibi.gd  (UPDATED — now extends base)
# LOCATION: res://scripts/npcs/npc_bibi.gd
# ════════════════════════════════════════════════════════════════

extends "res://scripts/npcs/npc_base.gd"

var _talked_today : bool = false


func _on_ready_override() -> void:
	move_speed        = 25.0   # very slow, elderly
	face_player_range = 80.0
	wait_at_waypoint  = 8.0    # long pauses — she rests often


func _on_interact() -> void:
	if _talked_today:
		DialogueManager.start([
			{ "speaker": "Bibi", "text": "Go, child. Muynak is waiting for you." }
		])
		return

	_talked_today = true
	DialogueManager.start_from_file("res://data/dialogue/bibi.json")

	# After full dialogue — give Rustam his first diary page
	await DialogueManager.dialogue_ended
	if not Diary.collected_pages().has("page_01"):
		Diary.collect("page_01")

	# After ch3 well activated — Bibi reacts
	if GameManager.well_activated and not _talked_today:
		DialogueManager.start([
			{ "speaker": "Bibi", "text": "I dreamed of water last night, child." },
			{ "speaker": "Bibi", "text": "Cold and clean. Like before." }
		])


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/npcs/npc_malik.gd
# LOCATION: res://scripts/npcs/npc_malik.gd
# Place in Hometown near a jeep Sprite2D
# ════════════════════════════════════════════════════════════════

extends "res://scripts/npcs/npc_base.gd"

var _ready_to_travel : bool = false
var _departed        : bool = false


func _on_ready_override() -> void:
	move_speed        = 55.0
	face_player_range = 128.0   # notices Rustam from far
	wait_at_waypoint  = 4.0


func _on_interact() -> void:
	if _departed:
		return

	# Only offer travel once Chapter 1 goals are met
	var ch1_done := GameManager.trees_planted >= 1 and \
				   DialogueManager != null

	if not ch1_done:
		DialogueManager.start([
			{ "speaker": "Malik", "text": "Whenever you are ready bro. No rush." },
			{ "speaker": "Malik", "text": "Actually there is a rush. The sea is dying." },
			{ "speaker": "Malik", "text": "Talk to your grandmother first. Then we go." }
		])
		return

	if not _ready_to_travel:
		_ready_to_travel = true
		DialogueManager.start([
			{ "speaker": "Malik", "text": "Okay. Bibi told me you are serious about this." },
			{ "speaker": "Malik", "text": "I have driven this road to Muynak fifty times." },
			{ "speaker": "Malik", "text": "Fifty times watching it get worse." },
			{ "speaker": "Malik", "text": "Let us go. I know a shortcut." }
		])
		await DialogueManager.dialogue_ended
		_trigger_travel_cutscene()


func _trigger_travel_cutscene() -> void:
	_departed = true
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

	DialogueManager.start([
		{ "speaker": "",      "text": "[Malik's jeep kicks up dust on the desert road...]" },
		{ "speaker": "Malik", "text": "You know what I hate most about this desert?" },
		{ "speaker": "Rustam","text": "The dust?" },
		{ "speaker": "Malik", "text": "No. That I remember when it was not desert." },
		{ "speaker": "",      "text": "[Muynak ahead. The ship graveyard emerges from the sand.]" }
	])

	await DialogueManager.dialogue_ended
	await ScreenFade.fade_out()
	GameManager.advance_chapter()


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/npcs/npc_guard.gd
# LOCATION: res://scripts/npcs/npc_guard.gd
# Place in Border.tscn patrolling the wall
# ════════════════════════════════════════════════════════════════

extends "res://scripts/npcs/npc_base.gd"

var _dialogue_stage  : int  = 0
var _gave_tnt        : bool = false
var _gave_photo      : bool = false


func _on_ready_override() -> void:
	move_speed        = 40.0
	face_player_range = 96.0
	wait_at_waypoint  = 12.0   # long patrol pauses at each end


func _on_interact() -> void:
	match _dialogue_stage:
		0:
			_dialogue_stage = 1
			DialogueManager.start([
				{ "speaker": "Guard", "text": "This is a restricted border zone. State your purpose." },
				{ "speaker": "Rustam","text": "I came from Muynak. I am trying to restore the sea." },
				{ "speaker": "Guard", "text": "...You came all the way from Muynak. On foot?" },
				{ "speaker": "Rustam","text": "Mostly." },
				{ "speaker": "Guard", "text": "My grandfather fished this sea. Before..." },
				{ "speaker": "Guard", "text": "Come. I will show you where the mines are. Watch your step." }
			])

		1:
			_dialogue_stage = 2
			DialogueManager.start([
				{ "speaker": "Guard", "text": "That wall. It was built to mark the border." },
				{ "speaker": "Guard", "text": "Now it also blocks the water flow from the north." },
				{ "speaker": "Guard", "text": "My superiors say it stays. But..." },
				{ "speaker": "Guard", "text": "I have TNT in the supply depot. Leftover from construction." },
				{ "speaker": "Guard", "text": "I cannot use it myself. But you are a civilian." }
			])
			await DialogueManager.dialogue_ended
			if not _gave_tnt:
				_gave_tnt = true
				Inventory.add_item("tnt", 1)
				# Also give the photo collectible
				if not _gave_photo:
					_gave_photo = true
					Photos.collect("photo_north_dam")

		2:
			DialogueManager.start([
				{ "speaker": "Guard", "text": "The TNT is yours. I was never here." },
				{ "speaker": "Guard", "text": "And Rustam? Whatever happens next —" },
				{ "speaker": "Guard", "text": "Both sides of this border want the sea back." },
				{ "speaker": "Guard", "text": "Do not forget that when you light the fuse." }
			])


# ════════════════════════════════════════════════════════════════
# FILE 4: res://scripts/npcs/npc_fisherman.gd
# LOCATION: res://scripts/npcs/npc_fisherman.gd
# Sits in one fixed spot in Muynak — never moves
# ════════════════════════════════════════════════════════════════

extends "res://scripts/npcs/npc_base.gd"

var _spoken : bool = false


func _on_ready_override() -> void:
	# No waypoints — he never moves
	waypoints        = []
	move_speed       = 0.0
	wait_at_waypoint = 999.0


func _on_interact() -> void:
	if _spoken:
		# Second time: just silence and a nod
		DialogueManager.start([
			{ "speaker": "", "text": "[He nods once. Does not look up from his net.]" }
		])
		return

	_spoken = true

	# These 3 lines are the saddest in the game. Do not change them.
	DialogueManager.start([
		{ "speaker": "", "text": "[An old man sits mending a net beside a ship that will never sail]" },
		{ "speaker": "Old Man", "text": "I used to leave at 4am. Back by noon. Boat full." },
		{ "speaker": "Old Man", "text": "Now I come here anyway. Habit, I suppose." },
		{ "speaker": "Old Man", "text": "The sea will come back. I will not. That is okay." },
		{ "speaker": "", "text": "[He returns to his net. You have nothing to say.]" }
	])
