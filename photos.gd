# PUSH 18 — Photo Collectibles + Memory System
# Commit: "Push 18: Photo collectibles, memory gallery, lore integration"
# "read diary and collect photo" — from Core Mechanics slide
#
# ════════════════════════════════════════════════════════════════
# FILE 1: res://scripts/systems/photo_collection.gd
# LOCATION: res://scripts/systems/photo_collection.gd
# REGISTER AS AUTOLOAD: Name it "Photos"
#   Project > Project Settings > Autoload > +
#   Name: Photos
# ════════════════════════════════════════════════════════════════

extends Node

signal photo_collected(photo_id: String)

# Each photo is a memory from the old Aral Sea.
# Rustam finds polaroids scattered in the world.
# Collecting all unlocks a secret ending slide.
const PHOTOS := {
	"photo_bibi_young": {
		"caption": "Bibi at the Aral Sea shore, 1962. She is laughing.",
		"location": "Near the well in Hometown",
		"texture":  "res://assets/sprites/photos/photo_bibi_young.png"
	},
	"photo_fishing_boat": {
		"caption": "Father's fishing boat. The catch was good that year.",
		"location": "Inside the largest ship wreck in Muynak",
		"texture":  "res://assets/sprites/photos/photo_fishing_boat.png"
	},
	"photo_aral_blue": {
		"caption": "The Aral Sea from above, 1975. Blue for as far as you can see.",
		"location": "Hidden under a salt crust in the Seafloor",
		"texture":  "res://assets/sprites/photos/photo_aral_blue.png"
	},
	"photo_rustam_child": {
		"caption": "Rustam, age 6. He does not know yet what is being lost.",
		"location": "In Bibi's house after her dialogue ends",
		"texture":  "res://assets/sprites/photos/photo_rustam_child.png"
	},
	"photo_north_dam": {
		"caption": "The Kokaral Dam, 2008. The North Aral Sea is coming back.",
		"location": "Given by the Kazakh guard in the Border level",
		"texture":  "res://assets/sprites/photos/photo_north_dam.png"
	},
}

var _collected : Array = []


func collect(photo_id: String) -> void:
	if photo_id in _collected:
		return
	if not PHOTOS.has(photo_id):
		push_warning("Photos: Unknown photo ID: %s" % photo_id)
		return

	_collected.append(photo_id)
	emit_signal("photo_collected", photo_id)

	var photo := PHOTOS[photo_id]
	DialogueManager.start([
		{ "speaker": "",       "text": "[Found a photograph]" },
		{ "speaker": "Rustam", "text": photo["caption"] },
		{ "speaker": "",       "text": "[Photo added to your collection]" }
	])


func get_photo(photo_id: String) -> Dictionary:
	return PHOTOS.get(photo_id, {})


func collected_photos() -> Array:
	return _collected.duplicate()


func all_collected() -> bool:
	return _collected.size() >= PHOTOS.size()


# ════════════════════════════════════════════════════════════════
# FILE 2: res://scripts/world/photo_pickup.gd
# LOCATION: res://scripts/world/photo_pickup.gd
# Attach to: Area2D for each photo in the world
# ════════════════════════════════════════════════════════════════

extends Area2D

@export var photo_id : String = "photo_bibi_young"


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Hide if already collected (persists after save/load)
	if photo_id in Photos.collected_photos():
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	Photos.collect(photo_id)
	SaveSystem.save()   # auto-save on collectible pickup
	queue_free()


# ════════════════════════════════════════════════════════════════
# FILE 3: res://scripts/ui/photo_gallery.gd
# LOCATION: res://scripts/ui/photo_gallery.gd
# Attach to: Control root of PhotoGallery.tscn
# Opened from base shelter by pressing Tab or from pause menu
# ════════════════════════════════════════════════════════════════

extends Control

@onready var grid          : GridContainer = $ScrollContainer/GridContainer
@onready var caption_label : Label         = $CaptionPanel/CaptionLabel
@onready var close_button  : Button        = $CloseButton

const PHOTO_SLOT := preload("res://scenes/ui/PhotoSlot.tscn")


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)
	Photos.photo_collected.connect(func(_id): _rebuild_grid())


func open_gallery() -> void:
	_rebuild_grid()
	visible = true


func _rebuild_grid() -> void:
	# Clear existing slots
	for child in grid.get_children():
		child.queue_free()

	# Add a slot per known photo
	for photo_id in Photos.PHOTOS.keys():
		var slot       := PHOTO_SLOT.instantiate()
		var collected  := photo_id in Photos.collected_photos()
		var photo_data := Photos.get_photo(photo_id)

		slot.setup(photo_id, collected, photo_data.get("texture", ""))
		slot.pressed.connect(func(): _show_caption(photo_data.get("caption", "")))
		grid.add_child(slot)


func _show_caption(text: String) -> void:
	caption_label.text = text


# ── SCENE STRUCTURE ───────────────────────────────────────────
# Control (photo_gallery.gd, fullrect)
# ├── PanelContainer  (dark background)
# │   ├── Label  "Rustam's Photographs"
# │   ├── ScrollContainer
# │   │   └── GridContainer (name: GridContainer, columns: 3)
# │   └── PanelContainer (name: CaptionPanel)
# │       └── Label (name: CaptionLabel)
# └── Button (name: CloseButton) text: "Close"
#
# Also create PhotoSlot.tscn:
#   Button (root)
#   └── TextureRect  (shows photo or dark placeholder if not collected)
#
# Place photo pickups in world:
#   photo_bibi_young  → Hometown, near Bibi's house
#   photo_fishing_boat→ Muynak, inside ship_01
#   photo_aral_blue   → Seafloor, hidden corner
#   photo_rustam_child→ Hometown, after Bibi dialogue ends
#   photo_north_dam   → Border level, given by Kazakh guard NPC
