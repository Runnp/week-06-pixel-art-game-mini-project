## inventory.gd
## Attached to: Autoload singleton (name it "Inventory")
## Handles: item pickup, tool equipping, item counts
## ─────────────────────────────────────────────────────────
## HOW TO REGISTER:
##   Project → Project Settings → Autoload
##   Path: res://scripts/systems/inventory.gd
##   Name: Inventory
## ─────────────────────────────────────────────────────────
## ITEMS IN THIS GAME:
##   Tools    → shovel, rake, spray_can, bolgarka, tnt
##   Pickups  → tree_sapling, fish, ship_part, water_sample
##   Key items→ diary_page, photo, blood_vial (well scene)
## ─────────────────────────────────────────────────────────

extends Node

# ── Signals ───────────────────────────────────────────────
signal item_added(item_name: String, new_count: int)
signal item_removed(item_name: String, new_count: int)
signal tool_equipped(tool_name: String)

# ── State ─────────────────────────────────────────────────
var items        : Dictionary = {}   # { "shovel": 1, "tree_sapling": 3, ... }
var equipped_tool: String     = ""   # currently held tool


# ══════════════════════════════════════════════════════════

# ── Add an item (pickup from world) ──────────────────────
func add_item(item_name: String, amount: int = 1) -> void:
    if items.has(item_name):
        items[item_name] += amount
    else:
        items[item_name] = amount

    emit_signal("item_added", item_name, items[item_name])


# ── Remove an item (used/consumed) ───────────────────────
func remove_item(item_name: String, amount: int = 1) -> bool:
    if not has_item(item_name, amount):
        return false   # not enough

    items[item_name] -= amount

    if items[item_name] <= 0:
        items.erase(item_name)

    emit_signal("item_removed", item_name, items.get(item_name, 0))
    return true


# ── Check if player has enough of an item ────────────────
func has_item(item_name: String, amount: int = 1) -> bool:
    return items.get(item_name, 0) >= amount


# ── Get count of an item ─────────────────────────────────
func count(item_name: String) -> int:
    return items.get(item_name, 0)


# ── Equip a tool (must already be in inventory) ───────────
func equip_tool(tool_name: String) -> void:
    if not has_item(tool_name):
        push_warning("Inventory: Cannot equip %s — not in inventory" % tool_name)
        return

    equipped_tool = tool_name
    emit_signal("tool_equipped", tool_name)


# ── Use the equipped tool on a target node ────────────────
func use_equipped_tool(target: Node) -> void:
    if equipped_tool == "":
        return

    if target.has_method("on_tool_used"):
        target.on_tool_used(equipped_tool)


# ── Debug helper: print current inventory ────────────────
func debug_print() -> void:
    print("── Inventory ──")
    for key in items:
        print("  %s: %d" % [key, items[key]])
    print("  Equipped: %s" % equipped_tool)
