# PUSH 07 — HUD Scene
# File: res://scripts/ui/hud.gd
# Commit: "Push 07: HUD built, health bar, tool label, restoration counters"
# Attach to: CanvasLayer root of HUD.tscn

extends CanvasLayer

@onready var health_bar  : ProgressBar = $VBoxContainer/HealthBar
@onready var tool_label  : Label       = $VBoxContainer/ToolLabel
@onready var trees_label : Label       = $VBoxContainer/RestorationBox/TreesLabel
@onready var ships_label : Label       = $VBoxContainer/RestorationBox/ShipsLabel
@onready var fish_label  : Label       = $VBoxContainer/RestorationBox/FishLabel
@onready var prompt      : Label       = $VBoxContainer/PromptLabel


func _ready() -> void:
	GameManager.player_health_changed.connect(_on_health_changed)
	GameManager.item_collected.connect(_on_item_collected)
	Inventory.tool_equipped.connect(_on_tool_equipped)

	health_bar.max_value = 100
	health_bar.value     = 100
	tool_label.text      = "No tool"
	prompt.visible       = false
	_refresh_restoration()


func _on_health_changed(new_health: int) -> void:
	var tween := create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.25)


func _on_tool_equipped(tool_name: String) -> void:
	tool_label.text = tool_name.replace("_", " ").capitalize()


func _on_item_collected(_item_name: String) -> void:
	_refresh_restoration()


func _refresh_restoration() -> void:
	trees_label.text = "Trees: %d"  % GameManager.trees_planted
	ships_label.text = "Ships: %d"  % GameManager.ships_scrapped
	fish_label.text  = "Fish:  %d"  % GameManager.fish_released


func show_prompt(text: String) -> void:
	prompt.text    = text
	prompt.visible = true


func hide_prompt() -> void:
	prompt.visible = false


func show_hud() -> void:
	visible = true


func hide_hud() -> void:
	visible = false


# ── SCENE STRUCTURE FOR HUD.tscn ─────────────────────────
# CanvasLayer
# └── VBoxContainer  (anchor: top-left, offset: 4,4)
#     ├── ProgressBar   (name: HealthBar)   min:0 max:100 value:100
#     ├── Label         (name: ToolLabel)
#     ├── Label         (name: PromptLabel)
#     └── VBoxContainer (name: RestorationBox)
#         ├── Label     (name: TreesLabel)
#         ├── Label     (name: ShipsLabel)
#         └── Label     (name: FishLabel)
#
# Add HUD.tscn as child of every level scene so it persists
