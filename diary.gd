# diary.gd
# ═══════════════════════════════════════════════════
# LOCATION: res://scripts/systems/diary.gd
# REGISTER AS AUTOLOAD: Name it "Diary"
#   Project > Project Settings > Autoload > +
#   Path: res://scripts/systems/diary.gd
#   Name: Diary
# ═══════════════════════════════════════════════════
# WHAT IT DOES:
#   Tracks collectible diary pages Rustam finds
#   throughout the world. Each page unlocks a lore
#   entry about the real Aral Sea crisis.
#   Player reads them from the HUD or base shelter.
#
# USAGE:
#   Diary.collect("page_01")        # when player picks up
#   Diary.get_entry("page_01")      # returns text content
#   Diary.collected_pages()         # returns Array of IDs
# ═══════════════════════════════════════════════════

extends Node

signal page_collected(page_id: String)

# All diary entries — add more as you design more pages
const ENTRIES := {
	"page_01": {
		"title": "1960 — The Great Plan",
		"text":  "The Soviet Union diverted the Amu Darya and Syr Darya rivers to irrigate cotton fields. Nobody asked what would happen to the sea they fed. In 1960 the Aral was the fourth largest lake on Earth."
	},
	"page_02": {
		"title": "1985 — First Signs",
		"text":  "My grandfather says the shoreline moved back by twenty kilometres in his lifetime. The fishing boats had to be dragged further and further on carts. Then one day they just... stopped dragging them."
	},
	"page_03": {
		"title": "1990s — The Ships",
		"text":  "Muynak had a cannery that processed twelve thousand tonnes of fish per year. By 1990 there were no fish. The cannery imported fish from the Baltic Sea just to stay open. The ships stayed where they were."
	},
	"page_04": {
		"title": "2000s — The Dust",
		"text":  "The exposed seabed contains salt, pesticide residue, and heavy metals from decades of runoff. Wind carries it two hundred kilometres. Children here have among the highest rates of throat cancer in Central Asia."
	},
	"page_05": {
		"title": "2005 — The North Sea Returns",
		"text":  "Kazakhstan built the Kokaral Dam with World Bank funding. The northern portion of the Aral Sea — the Small Aral — began refilling. Fish returned within two years. It is possible."
	},
	"page_06": {
		"title": "Grandmother's Note",
		"text":  "She kept a photograph. Blue water, a wooden boat, her face laughing. She is eighteen. Behind her: the Aral Sea. She never threw the photograph away. I think she always believed it would come back."
	},
}

var _collected : Array = []   # IDs of pages found so far


func collect(page_id: String) -> void:
	if page_id in _collected:
		return
	if not ENTRIES.has(page_id):
		push_warning("Diary: Unknown page ID: %s" % page_id)
		return

	_collected.append(page_id)
	emit_signal("page_collected", page_id)

	var entry := ENTRIES[page_id]
	DialogueManager.start([
		{ "speaker": "Diary",           "text": entry["title"] },
		{ "speaker": "",                "text": entry["text"]  },
		{ "speaker": "Rustam",          "text": "I should keep this." }
	])


func get_entry(page_id: String) -> Dictionary:
	return ENTRIES.get(page_id, {})


func collected_pages() -> Array:
	return _collected.duplicate()


func total_pages() -> int:
	return ENTRIES.size()


func completion_ratio() -> float:
	return float(_collected.size()) / float(total_pages())


# ═══════════════════════════════════════════════════
# HOW TO PLACE DIARY PAGES IN THE WORLD:
#
# Use pickup_item.gd (Push 09) on an Area2D.
# Set item_name to the page ID e.g. "page_01"
# Then in pickup_item.gd's _on_body_entered, add:
#
#   if item_name.begins_with("page_"):
#       Diary.collect(item_name)
#       return   # diary handles its own dialogue
#
# Scatter pages:
#   page_01 → Hometown (near Bibi's house)
#   page_02 → Hometown outskirts
#   page_03 → Muynak (by the ships)
#   page_04 → Muynak (near dust pile)
#   page_05 → Seafloor (near the well)
#   page_06 → Seafloor (hidden corner, hardest to find)
# ═══════════════════════════════════════════════════
