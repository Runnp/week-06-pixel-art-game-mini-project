extends Node

signal night_started
signal day_started

var is_night : bool = false


func _ready() -> void:
	# Connect to DayCycle via group signal
	get_tree().call_group("day_cycle", "connect_night_manager", self)


func on_phase_changed(phase_name: String) -> void:
	match phase_name:
		"NIGHT":
			is_night = true
			emit_signal("night_started")
			_apply_night()
		"DAY":
			is_night = false
			emit_signal("day_started")
			_apply_day()


func _apply_night() -> void:
	# NPCs stop patrolling and go inside
	get_tree().call_group("npc", "on_night_start")

	# Enemies become more aggressive at night
	get_tree().call_group("enemy", "set", "detect_range", 140.0)
	get_tree().call_group("enemy", "set", "chase_speed",
		# Override: 20% faster at night
		0.0)   # can't set formula this way — use signal instead

	# Prompt player to use lantern if they have one
	if Inventory.has_item("lantern"):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_prompt("Night falls. Equip lantern [E]")
			await get_tree().create_timer(3.0).timeout
			hud.hide_prompt()
	else:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_prompt("⚠ Dark. Find a lantern or shelter.")
			await get_tree().create_timer(3.0).timeout
			hud.hide_prompt()


func _apply_day() -> void:
	get_tree().call_group("npc", "on_day_start")
	get_tree().call_group("enemy", "set", "detect_range", 100.0)
