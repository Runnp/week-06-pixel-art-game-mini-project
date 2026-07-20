extends Node

@export var spawn_points     : Array[NodePath] = []
@export var enemy_scene      : PackedScene     = null
@export var max_alive        : int             = 4
@export var respawn_delay    : float           = 20.0
@export var respawn_on_return: bool            = true

var _alive_enemies   : Array  = []
var _respawn_timers  : Array  = []
var _spawn_nodes     : Array  = []


func _ready() -> void:
	for path in spawn_points:
		var node := get_node_or_null(path)
		if node:
			_spawn_nodes.append(node)

	# Initial spawn
	for i in min(max_alive, _spawn_nodes.size()):
		_spawn_at(i)

	GameManager.item_collected.connect(_on_restoration)


func _process(_delta: float) -> void:
	# Clean dead enemies from list
	_alive_enemies = _alive_enemies.filter(
		func(e): return is_instance_valid(e)
	)

	# Tick respawn timers
	for i in _respawn_timers.size():
		if _respawn_timers[i] > 0:
			_respawn_timers[i] -= get_process_delta_time()
			if _respawn_timers[i] <= 0 and _alive_enemies.size() < _max_allowed():
				_spawn_at(i % _spawn_nodes.size())


func _spawn_at(index: int) -> void:
	if enemy_scene == null or index >= _spawn_nodes.size():
		return
	if _alive_enemies.size() >= _max_allowed():
		return

	var enemy              := enemy_scene.instantiate()
	enemy.global_position   = _spawn_nodes[index].global_position
	_apply_difficulty(enemy)
	get_parent().add_child(enemy)
	_alive_enemies.append(enemy)

	# Connect death signal to schedule respawn
	if enemy.has_signal("tree_exited"):
		pass   # handled via _process cleanup above


func _apply_difficulty(enemy: Node) -> void:
	var pct := WorldState.get_restoration_percent()
	# As restoration increases, enemies get weaker
	var mult := 1.0 - (pct * 0.35)   # max 35% weaker at full restoration

	if enemy.has_method("get") and enemy.get("max_health") != null:
		enemy.max_health    = int(enemy.max_health    * mult)
		enemy.health        = enemy.max_health
		enemy.chase_speed   = enemy.chase_speed   * (1.0 - pct * 0.2)
		enemy.attack_damage = int(enemy.attack_damage * mult)


func _max_allowed() -> int:
	var pct := WorldState.get_restoration_percent()
	# Fewer enemies as world heals
	return max(1, int(max_alive * (1.0 - pct * 0.5)))


func _on_restoration(_item: String) -> void:
	# When restoration progresses, weaken existing enemies too
	for enemy in _alive_enemies:
		if is_instance_valid(enemy):
			enemy.max_health = max(5,
				int(enemy.max_health * 0.95))


func schedule_respawn(spawn_index: int) -> void:
	while _respawn_timers.size() <= spawn_index:
		_respawn_timers.append(0.0)
	_respawn_timers[spawn_index] = respawn_delay
