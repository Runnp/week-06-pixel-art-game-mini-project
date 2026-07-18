# PUSH 49 — Debug Console + Developer Tools
# Commit: "Push 49: Debug console, cheat commands, level skip, state inspector"
# File: res://scripts/systems/debug_console.gd
# REGISTER AS AUTOLOAD: Name it "DebugConsole"
# ═══════════════════════════════════════════════════════════════
# WHAT THIS DOES:
#   Press F1 to open a developer console.
#   Type commands to skip levels, add items, test enemies.
#   ONLY active in debug builds — disabled in exports.
#   Essential for testing without playing through every level.
# ═══════════════════════════════════════════════════════════════

extends CanvasLayer

var _visible   : bool   = false
var _history   : Array  = []
var _hist_idx  : int    = 0

@onready var panel      : PanelContainer = $Panel
@onready var output     : RichTextLabel  = $Panel/VBox/OutputLabel
@onready var input_field: LineEdit       = $Panel/VBox/InputField


func _ready() -> void:
	layer         = 99
	panel.visible = false

	if not OS.is_debug_build():
		set_process_input(false)
		return   # disabled in release builds

	input_field.text_submitted.connect(_on_command)
	_log("[Debug Console ready. Press F1 to toggle.]", Color.YELLOW)
	_log("Type 'help' for command list.", Color.GRAY)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_toggle()
		elif _visible and event.keycode == KEY_UP:
			_navigate_history(-1)
		elif _visible and event.keycode == KEY_DOWN:
			_navigate_history(1)


func _toggle() -> void:
	_visible      = not _visible
	panel.visible = _visible
	if _visible:
		input_field.grab_focus()
		get_tree().paused = true
	else:
		get_tree().paused = false


func _navigate_history(dir: int) -> void:
	if _history.is_empty():
		return
	_hist_idx = clamp(_hist_idx + dir, 0, _history.size() - 1)
	input_field.text = _history[_hist_idx]


func _on_command(text: String) -> void:
	if text.strip_edges() == "":
		return
	_history.append(text)
	_hist_idx = _history.size()
	_log("> " + text, Color.WHITE)
	input_field.clear()
	_execute(text.strip_edges().to_lower())


func _execute(cmd: String) -> void:
	var parts := cmd.split(" ")
	var verb  := parts[0]
	var args  := parts.slice(1)

	match verb:
		"help":
			_log("""Commands:
  goto [1-5]         — jump to chapter
  scene [path]       — load scene directly
  health [0-100]     — set player health
  give [item] [n]    — add item to inventory
  equip [tool]       — equip a tool
  kill_all           — remove all enemies
  weather [type]     — set weather (clear/windy/dusty/storm)
  restore_all        — max out all restoration counters
  unlock_well        — trigger well activation
  win                — skip to ending
  chapter            — print current chapter
  pos                — print player position
  fps                — toggle FPS counter
  clear              — clear console
  close              — close console""", Color.CYAN)

		"goto":
			if args.size() > 0:
				var ch := int(args[0])
				GameManager.current_chapter = ch - 1
				GameManager.advance_chapter()
				_log("Jumping to chapter %d" % ch, Color.GREEN)
				_toggle()

		"scene":
			if args.size() > 0:
				var path := " ".join(args)
				if not path.begins_with("res://"):
					path = "res://scenes/levels/" + path + ".tscn"
				GameManager.change_scene(path)
				_log("Loading: " + path, Color.GREEN)
				_toggle()

		"health":
			var player := get_tree().get_first_node_in_group("player")
			if player and args.size() > 0:
				var hp := int(args[0])
				player.health = clamp(hp, 0, player.MAX_HEALTH)
				GameManager.emit_signal("player_health_changed", player.health)
				_log("Health set to %d" % player.health, Color.GREEN)

		"give":
			if args.size() >= 1:
				var item   := args[0]
				var amount := int(args[1]) if args.size() > 1 else 1
				Inventory.add_item(item, amount)
				_log("Added %d x %s" % [amount, item], Color.GREEN)

		"equip":
			if args.size() > 0:
				var tool := args[0]
				Inventory.add_item(tool, 1)
				Inventory.equip_tool(tool)
				_log("Equipped: " + tool, Color.GREEN)

		"kill_all":
			var enemies := get_tree().get_nodes_in_group("enemy")
			for e in enemies:
				e.queue_free()
			_log("Removed %d enemies" % enemies.size(), Color.GREEN)

		"weather":
			if args.size() > 0:
				match args[0]:
					"clear":   WeatherManager._transition_to(WeatherManager.WeatherType.CLEAR)
					"windy":   WeatherManager._transition_to(WeatherManager.WeatherType.WINDY)
					"dusty":   WeatherManager._transition_to(WeatherManager.WeatherType.DUSTY)
					"storm":   WeatherManager._transition_to(WeatherManager.WeatherType.SANDSTORM)
				_log("Weather set to: " + args[0], Color.GREEN)

		"restore_all":
			GameManager.trees_planted  = 7
			GameManager.ships_scrapped = 3
			GameManager.fish_released  = 5
			GameManager.emit_signal("item_collected", "tree")
			_log("All restoration maxed", Color.GREEN)

		"unlock_well":
			GameManager.activate_well()
			_log("Well activated", Color.GREEN)

		"win":
			await ScreenFade.fade_out(0.5)
			GameManager.change_scene("res://scenes/ui/Credits.tscn")

		"chapter":
			_log("Current chapter: %d" % GameManager.current_chapter, Color.CYAN)

		"pos":
			var player := get_tree().get_first_node_in_group("player")
			if player:
				_log("Player pos: %s  tile: %s" % [
					str(player.global_position),
					str(player.global_position / 32.0)
				], Color.CYAN)

		"fps":
			Engine.max_fps = 0 if Engine.max_fps == 60 else 60
			_log("FPS display toggled", Color.CYAN)

		"clear":
			output.clear()

		"close":
			_toggle()

		_:
			_log("Unknown command: " + verb, Color.RED)
			_log("Type 'help' for commands", Color.GRAY)


func _log(text: String, color: Color = Color.WHITE) -> void:
	output.append_text("[color=#%s]%s[/color]\n" % [
		color.to_html(false), text
	])
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll := output.get_v_scroll_bar()
	if scroll:
		scroll.value = scroll.max_value


# ── SCENE STRUCTURE: DebugConsole is built in _ready() ────────
# No .tscn needed — but add these nodes as children:
#
# CanvasLayer (debug_console.gd, layer: 99)
# └── PanelContainer (name: Panel, size: 300x180, pos: 8,0)
#     └── VBoxContainer (name: VBox)
#         ├── RichTextLabel (name: OutputLabel, size: 300x155, bbcode:ON)
#         └── LineEdit      (name: InputField, size: 300x20)
#               placeholder: "Enter command..."
#
# Or create the nodes in code — add to _ready() after the check:
#   panel = PanelContainer.new()
#   ... etc
