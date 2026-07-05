# dust_storm.gd
# ═══════════════════════════════════════════════════
# LOCATION: res://scripts/world/dust_storm.gd
# ATTACH TO: Node2D named "DustStorm" in any level
# ═══════════════════════════════════════════════════
# WHAT IT DOES:
#   Periodic dust storm hazard unique to the Aral Sea
#   setting. Triggered on a random timer — player must
#   reach shelter (a marked Area2D) before storm hits
#   or take continuous damage.
#
# SCENE STRUCTURE:
#   Node2D  (name: DustStorm)
#   ├── Timer          (name: StormTimer)
#   ├── ColorRect      (name: StormOverlay) fullrect brown tint
#   └── (attach this script)
#
#   Also place in the level:
#   Area2D  (name: Shelter, group: "shelter")
#   └── CollisionShape2D
# ═══════════════════════════════════════════════════

extends Node2D

@onready var storm_timer   : Timer    = $StormTimer
@onready var storm_overlay : ColorRect = $StormOverlay

const STORM_INTERVAL_MIN := 25.0   # seconds between storms
const STORM_INTERVAL_MAX := 45.0
const STORM_DURATION     := 8.0    # how long storm lasts
const STORM_DAMAGE       := 3      # damage per second inside storm
const WARNING_TIME       := 4.0    # seconds of warning before storm hits

var _storm_active  : bool = false
var _player_safe   : bool = false
var _damage_timer  : float = 0.0


func _ready() -> void:
	storm_overlay.color   = Color(0.6, 0.45, 0.2, 0.0)
	storm_timer.wait_time = randf_range(STORM_INTERVAL_MIN, STORM_INTERVAL_MAX)
	storm_timer.timeout.connect(_begin_warning)
	storm_timer.start()


func _process(delta: float) -> void:
	if not _storm_active:
		return

	# Check if player is sheltered
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	_player_safe = _is_player_in_shelter(player)

	if not _player_safe:
		_damage_timer += delta
		if _damage_timer >= 1.0:
			_damage_timer = 0.0
			player.take_damage(STORM_DAMAGE)


func _is_player_in_shelter(player: Node2D) -> bool:
	var shelters := get_tree().get_nodes_in_group("shelter")
	for shelter in shelters:
		if shelter is Area2D:
			# Check overlap manually via distance (simple approach)
			if shelter.global_position.distance_to(player.global_position) < 32.0:
				return true
	return false


func _begin_warning() -> void:
	# Warn player via dialogue
	DialogueManager.start([
		{ "speaker": "", "text": "[The wind picks up. A dust storm is coming — find shelter!]" }
	])

	# Start the orange tint building
	var tween := create_tween()
	tween.tween_property(storm_overlay, "color:a", 0.3, WARNING_TIME)
	await tween.finished

	_start_storm()


func _start_storm() -> void:
	_storm_active  = true
	_damage_timer  = 0.0

	var tween := create_tween()
	tween.tween_property(storm_overlay, "color:a", 0.65, 1.0)

	await get_tree().create_timer(STORM_DURATION).timeout
	_end_storm()


func _end_storm() -> void:
	_storm_active = false

	var tween := create_tween()
	tween.tween_property(storm_overlay, "color:a", 0.0, 2.0)

	# Reset timer for next storm
	storm_timer.wait_time = randf_range(STORM_INTERVAL_MIN, STORM_INTERVAL_MAX)
	storm_timer.start()

	DialogueManager.start([
		{ "speaker": "", "text": "[The storm passes. The dust settles.]" }
	])
