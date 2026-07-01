extends CanvasLayer

@onready var health_bar  : ProgressBar = $VBoxContainer/HealthBar
@onready var tool_label  : Label       = $VBoxContainer/ToolLabel
@onready var trees_label : Label       = $VBoxContainer/RestorationBox/TreesLabel
@onready var ships_label : Label       = $VBoxContainer/RestorationBox/ShipsLabel
@onready var fish_label  : Label       = $VBoxContainer/RestorationBox/FishLabel

func _ready() -> void:
    GameManager.player_health_changed.connect(_on_health_changed)
    GameManager.item_collected.connect(_on_item_collected)
    Inventory.tool_equipped.connect(_on_tool_equipped)

    health_bar.max_value = 100
    health_bar.value     = 100
    tool_label.text      = "No tool"
    _refresh_restoration()

func _on_health_changed(new_health: int) -> void:
    var tween := create_tween()
    tween.tween_property(health_bar, "value", new_health, 0.25)

func _on_tool_equipped(tool_name: String) -> void:
    tool_label.text = tool_name.replace("_", " ").capitalize()

func _on_item_collected(_item_name: String) -> void:
    _refresh_restoration()

func _refresh_restoration() -> void:
    trees_label.text = "Trees planted: %d" % GameManager.trees_planted
    ships_label.text = "Ships scrapped: %d" % GameManager.ships_scrapped
    fish_label.text  = "Fish released: %d"  % GameManager.fish_released

func show_hud() -> void:
    visible = true

func hide_hud() -> void:
    visible = false
