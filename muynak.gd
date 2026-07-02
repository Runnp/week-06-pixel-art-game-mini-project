# PUSH 11 — Muynak Level (Chapter 2)
# File: res://scripts/levels/muynak_level.gd
# Commit: "Push 11: Muynak level, ship graveyard, Chapter 2 setup"
# Attach to: root Node2D of Muynak.tscn

extends Node2D

# How many ships Rustam must scrap before Chapter 2 ends
const SHIPS_TO_SCRAP := 3


func _ready() -> void:
	GameManager.item_collected.connect(_on_item_collected)
	_show_arrival_dialogue()


func _show_arrival_dialogue() -> void:
	DialogueManager.start([
		{ "speaker": "",       "text": "[Muynak. Once a harbour city. Now a graveyard of ships.]" },
		{ "speaker": "Rustam", "text": "These boats... they fished the Aral Sea. Now they rust in desert sand." },
		{ "speaker": "Rustam", "text": "I need to clear this place. Start the restoration." },
		{ "speaker": "",       "text": "[Equip the bolgarka and approach the ships]" }
	])


func _on_item_collected(item_name: String) -> void:
	if item_name != "ship_part":
		return

	if GameManager.ships_scrapped >= SHIPS_TO_SCRAP:
		_chapter_complete()


func _chapter_complete() -> void:
	DialogueManager.start([
		{ "speaker": "Rustam", "text": "The ships are cleared. The sea floor is open." },
		{ "speaker": "Rustam", "text": "Now — the soil. The plants. The well." },
		{ "speaker": "",       "text": "[Head south toward the dry seabed — Chapter 3 awaits]" }
	])

	await get_tree().create_timer(4.0).timeout
	GameManager.advance_chapter()


# ── SCENE STRUCTURE FOR Muynak.tscn ──────────────────────
# Node2D  (name: Muynak)
# ├── TileMapLayer         (painted desert/sand tiles)
# ├── HUD.tscn             (instance here)
# ├── DialogueBox.tscn     (instance here)
# ├── ShipWreck_01         (StaticBody2D + ship_wreck.gd)
# ├── ShipWreck_02
# ├── ShipWreck_03
# ├── DustDrifter_01       (enemy instances)
# ├── DustDrifter_02
# ├── PickupItem_Bolgarka  (Area2D + pickup_item.gd  item_name:"bolgarka")
# └── LevelDoor            (leads to Chapter 3 Seafloor — unlocked after ships cleared)
