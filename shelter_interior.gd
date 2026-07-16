# PUSH 41 — Base Shelter Interior + Rest System
# Commit: "Push 41: Shelter interior scene, sleep mechanic, inventory review, diary read"
# File: res://scripts/levels/shelter_interior.gd
# Attach to: root Node2D of ShelterInterior.tscn
# ═══════════════════════════════════════════════════════════════
# WHAT THIS IS:
#   A separate small scene — Rustam's base camp interior.
#   Entered by interacting with his tent/room door in Hometown.
#   Size: 10x8 tiles (320x256px — exactly one screen, no camera scroll)
#   Contains: bed, aquarium, shelf, diary, exit door
#   This is the only safe place in the game. No enemies. No traps.
#   Player rests here to restore health fully.
# ═══════════════════════════════════════════════════════════════

extends Node2D

@onready var bed_area      : Area2D = $BedArea
@onready var shelf_area    : Area2D = $ShelfArea
@onready var exit_door     : Area2D = $ExitDoor
@onready var fade_overlay  : ColorRect = $FadeOverlay
@onready var time_label    : Label     = $TimeLabel

var _from_scene : String = ""
var _resting    : bool   = false


func _ready() -> void:
	await ScreenFade.fade_in(0.4)
	_from_scene = GameManager.CHAPTER_SCENES.get(
		GameManager.current_chapter, ""
	)
	bed_area.body_entered.connect(_on_bed_entered)
	exit_door.body_entered.connect(_on_exit_entered)
	_update_time_display()


func _update_time_display() -> void:
	if time_label:
		var hour := (int(Time.get_ticks_msec() / 1000.0) % 24)
		time_label.text = "%02d:00" % hour


# ── BED — rest and heal ───────────────────────────
func _on_bed_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _resting:
		return
	_resting = true
	body.can_move = false
	_rest_sequence(body)


func _rest_sequence(player: Node2D) -> void:
	DialogueManager.start([
		{ "speaker": "",       "text": "[Rustam lies down. He is exhausted.]" },
		{ "speaker": "Rustam", "text": "Just a few hours." },
		{ "speaker": "",       "text": "[He closes his eyes.]" }
	])

	await DialogueManager.dialogue_ended

	# Fade to black — sleep transition
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.5)
	await tween.finished

	# Restore health fully
	player.health = player.MAX_HEALTH
	GameManager.emit_signal("player_health_changed", player.health)

	# Save progress
	SaveSystem.save()

	await get_tree().create_timer(1.0).timeout

	# Fade back in
	var tween2 := create_tween()
	tween2.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	await tween2.finished

	DialogueManager.start([
		{ "speaker": "",       "text": "[Morning. Rustam feels stronger.]" },
		{ "speaker": "Rustam", "text": "Back to work." }
	])

	await DialogueManager.dialogue_ended
	player.can_move = true
	_resting        = false
	_update_time_display()


# ── EXIT DOOR — return to level ───────────────────
func _on_exit_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	body.can_move = false
	await ScreenFade.fade_out(0.4)
	GameManager.change_scene(_from_scene)


# ═══════════════════════════════════════════════════════════════
# SCENE STRUCTURE: ShelterInterior.tscn
# Save at: res://scenes/levels/ShelterInterior.tscn
# ═══════════════════════════════════════════════════════════════
#
# Node2D (name: ShelterInterior, attach shelter_interior.gd)
# ├── TileMapLayer          10x8 tiles, interior tileset
# ├── ColorRect             (name: FadeOverlay) fullrect black alpha:0
# ├── Label                 (name: TimeLabel) top-right corner
# ├── Player.tscn           starts at tile (5,6)
# │
# ├── Area2D (name: BedArea)           tile (2,2) — (3,3)
# │   ├── CollisionShape2D  RectangleShape2D 64x32
# │   └── Sprite2D          bed sprite 64x32px
# │
# ├── Area2D (name: AquariumNode)      tile (7,2)
# │   └── (aquarium.gd — from Push 17)
# │
# ├── StaticBody2D (name: Shelf)       tile (1,1)
# │   ├── CollisionShape2D  32x16
# │   ├── Sprite2D          shelf sprite
# │   └── (prop_interact.gd)
# │         lines: "[Your tools and supplies. Ready for tomorrow.]"
# │
# ├── StaticBody2D (name: DiaryShelf)  tile (8,4)
# │   └── (inline interact — opens photo gallery)
# │         func interact():
# │           var gallery := get_tree().get_first_node_in_group("photo_gallery")
# │           if gallery: gallery.open_gallery()
# │
# └── Area2D (name: ExitDoor)          tile (5,7) — south edge
#     └── CollisionShape2D  32x16


# ═══════════════════════════════════════════════════════════════
# SHELTER DOOR — add to Hometown.tscn
# This is what the player interacts with to ENTER the shelter
# ═══════════════════════════════════════════════════════════════

# Place this as a child of Hometown.tscn near Bibi's house:
#
# StaticBody2D (name: ShelterDoor)
# ├── CollisionShape2D  RectangleShape2D 32x8
# ├── Sprite2D          door sprite
# └── Script (inline):
#
#     extends StaticBody2D
#     func interact() -> void:
#         await ScreenFade.fade_out(0.3)
#         GameManager.change_scene("res://scenes/levels/ShelterInterior.tscn")
