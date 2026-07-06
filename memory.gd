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
