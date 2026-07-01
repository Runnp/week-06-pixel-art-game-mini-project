## game_manager.gd
## Attached to: Autoload singleton (name it "GameManager" in Project Settings)
## Handles: global signals, chapter state, scene transitions
## ─────────────────────────────────────────────────────────
## HOW TO REGISTER:
##   Project → Project Settings → Autoload
##   Path: res://scripts/systems/game_manager.gd
##   Name: GameManager
## ─────────────────────────────────────────────────────────

extends Node

# ── Signals (any script can connect to these) ─────────────
signal player_health_changed(new_health: int)
signal player_died
signal chapter_changed(chapter_number: int)
signal item_collected(item_name: String)

# ── Game State ────────────────────────────────────────────
var current_chapter : int  = 1
var player_health   : int  = 100

# ── Restoration progress (drives the ending) ──────────────
var trees_planted   : int  = 0
var ships_scrapped  : int  = 0
var fish_released   : int  = 0
var well_activated  : bool = false

# ── Chapter scene map ─────────────────────────────────────
const CHAPTER_SCENES := {
    1: "res://scenes/levels/Hometown.tscn",
    2: "res://scenes/levels/Muynak.tscn",
    3: "res://scenes/levels/Seafloor.tscn",
    4: "res://scenes/levels/Border.tscn",
}


# ══════════════════════════════════════════════════════════
func _ready() -> void:
    # Connect internal signals so health changes save to state
    player_health_changed.connect(_on_health_changed)
    player_died.connect(_on_player_died)


# ── Go to next chapter ────────────────────────────────────
func advance_chapter() -> void:
    current_chapter += 1
    emit_signal("chapter_changed", current_chapter)

    if CHAPTER_SCENES.has(current_chapter):
        change_scene(CHAPTER_SCENES[current_chapter])
    else:
        push_warning("GameManager: No scene mapped for chapter %d" % current_chapter)


# ── Load any scene by path ────────────────────────────────
func change_scene(path: String) -> void:
    get_tree().change_scene_to_file(path)


# ── Restoration trackers ──────────────────────────────────
func plant_tree() -> void:
    trees_planted += 1
    emit_signal("item_collected", "tree")

func scrap_ship() -> void:
    ships_scrapped += 1
    emit_signal("item_collected", "ship_part")

func release_fish() -> void:
    fish_released += 1
    emit_signal("item_collected", "fish")

func activate_well() -> void:
    well_activated = true
    emit_signal("item_collected", "well")


# ── Internal handlers ─────────────────────────────────────
func _on_health_changed(new_health: int) -> void:
    player_health = new_health

func _on_player_died() -> void:
    # Small delay then reload current chapter
    await get_tree().create_timer(1.5).timeout
    change_scene(CHAPTER_SCENES[current_chapter])
