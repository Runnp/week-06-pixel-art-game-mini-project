extends Node

signal dialogue_started
signal dialogue_ended

var active := false
var current_lines := []
var current_index := 0

@onready var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")

func start_dialogue(lines: Array):
    active = true
    current_lines = lines
    current_index = 0
    emit_signal("dialogue_started")
    show_line()

func advance():
    current_index += 1
    if current_index >= current_lines.size():
        end_dialogue()
    else:
        show_line()

func show_line():
    var line = current_lines[current_index]
    dialogue_ui.display(line.get("speaker", ""), line.get("text", ""))

func end_dialogue():
    active = false
    dialogue_ui.hide()
    emit_signal("dialogue_ended")
