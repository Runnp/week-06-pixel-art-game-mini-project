# PUSH 09 — Inventory Pickups
# File: res://scripts/systems/pickup_item.gd
# Commit: "Push 09: Pickup system, shovel/spray_can/tree_sapling items"
# Attach to: Area2D node for each pickup in the world

extends Area2D

@export var item_name  : String = "shovel"   # set in Inspector per pickup
@export var amount     : int    = 1
@export var auto_equip : bool   = false       # true for tools, false for consumables


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	Inventory.add_item(item_name, amount)

	if auto_equip:
		Inventory.equip_tool(item_name)

	# Show pickup message via HUD
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_prompt("Picked up: %s" % item_name.replace("_", " ").capitalize())
		await get_tree().create_timer(1.5).timeout
		hud.hide_prompt()

	queue_free()   # Remove pickup from world


# ── SCENE STRUCTURE FOR each Pickup ──────────────────────
# Area2D
# ├── Sprite2D or AnimatedSprite2D  (item icon pixel art)
# ├── CollisionShape2D  CircleShape2D  radius:10
# └── (attach pickup_item.gd)
#     Set item_name in Inspector:
#       "shovel"        auto_equip: true
#       "rake"          auto_equip: true
#       "spray_can"     auto_equip: true
#       "bolgarka"      auto_equip: true
#       "tree_sapling"  auto_equip: false  amount: 3
#       "fish"          auto_equip: false  amount: 1
#       "diary_page"    auto_equip: false  amount: 1


# ════════════════════════════════════════════════════════════════
# ITEMS REFERENCE — what each item does in gameplay
# ════════════════════════════════════════════════════════════════
#
# shovel      → used on DirtPatch nodes → triggers dig animation
# rake        → used on SaltCrust nodes → clears path
# spray_can   → used on SoilPatch nodes → plants restoration progress
# bolgarka    → used on ShipWreck nodes → scraps ship parts
# tnt         → used on NorthWall node  → final act explosion
# tree_sapling→ consumed when planting (need 1 per tree)
# fish        → released at water's edge in final act
# diary_page  → collectible, unlocks lore entries
# blood_vial  → key item, auto-collected at magic well scene
