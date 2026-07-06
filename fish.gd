extends Node2D

# Fish health decays over real time (or in-game days).
# Player feeds them by interacting while holding fish food.
# When the sea is restored in the finale, these fish get released.

const MAX_FISH       := 5
const DECAY_INTERVAL := 30.0   # seconds per health tick
const DECAY_AMOUNT   := 10

@onready var fish_label   : Label = $Label
@onready var decay_timer  : Timer = $DecayTimer

var fish_count  : int = 0
var fish_health : int = 100   # 0 = fish die, 100 = healthy


func _ready() -> void:
	decay_timer.wait_time = DECAY_INTERVAL
	decay_timer.timeout.connect(_on_decay)
	decay_timer.start()
	_update_label()


func interact() -> void:
	if fish_count == 0:
		DialogueManager.start([
			{ "speaker": "Rustam", "text": "The aquarium is empty. I need to catch fish first." }
		])
		return

	if Inventory.has_item("fish_food"):
		_feed_fish()
	elif Inventory.has_item("fish"):
		_add_fish()
	else:
		_inspect_fish()


func _add_fish() -> void:
	if fish_count >= MAX_FISH:
		DialogueManager.start([
			{ "speaker": "Rustam", "text": "The tank is full. These fish are ready for the sea." }
		])
		return

	Inventory.remove_item("fish")
	fish_count += 1
	_update_label()

	DialogueManager.start([
		{ "speaker": "Rustam", "text": "There you go little one. You are safe here for now." },
		{ "speaker": "",       "text": "[Fish in aquarium: %d / %d]" % [fish_count, MAX_FISH] }
	])


func _feed_fish() -> void:
	Inventory.remove_item("fish_food")
	fish_health = min(fish_health + 30, 100)
	_update_label()

	DialogueManager.start([
		{ "speaker": "Rustam", "text": "There you go. Eat up." },
		{ "speaker": "",       "text": "[Fish health: %d%%]" % fish_health }
	])


func _inspect_fish() -> void:
	var status := "healthy" if fish_health > 60 else ("stressed" if fish_health > 30 else "critical")
	DialogueManager.start([
		{ "speaker": "Rustam", "text": "I have %d fish. They look %s." % [fish_count, status] },
		{ "speaker": "Rustam", "text": "I should find fish food to keep them alive." }
	])


func _on_decay() -> void:
	if fish_count == 0:
		return

	fish_health -= DECAY_AMOUNT
	fish_health  = max(fish_health, 0)
	_update_label()

	if fish_health == 0:
		_fish_died()


func _fish_died() -> void:
	fish_count  = max(fish_count - 1, 0)
	fish_health = 50   # reset for remaining fish

	DialogueManager.start([
		{ "speaker": "",       "text": "[A fish died. The water quality is too low.]" },
		{ "speaker": "Rustam", "text": "No... I need to take better care of them." }
	])
	_update_label()


func _update_label() -> void:
	if fish_label:
		fish_label.text = "Fish: %d  Health: %d%%" % [fish_count, fish_health]


# Called by rising_water.gd finale to release all fish
func release_all_fish() -> void:
	GameManager.fish_released += fish_count
	GameManager.emit_signal("item_collected", "fish")
	DialogueManager.start([
		{ "speaker": "Rustam", "text": "Go. The sea is yours again." },
		{ "speaker": "",       "text": "[%d fish released into the restored Aral Sea]" % fish_count }
	])
	fish_count  = 0
	fish_health = 100
	_update_label()
