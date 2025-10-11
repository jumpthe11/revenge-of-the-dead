extends Node3D

class_name AISpawner

## Performance-optimized AI spawning system
## Manages enemy spawning, pooling, and cleanup

signal enemy_spawned(enemy: AIEnemyBase)
signal enemy_destroyed(enemy: AIEnemyBase)
signal spawn_wave_complete
signal all_enemies_defeated

@export_group("Spawn Settings")
## Maximum number of active enemies
@export var max_active_enemies: int = 10
## Spawn positions (empty array = use spawner positions)
@export var spawn_points: Array[Vector3] = []
## Whether to use enemy pooling for performance
@export var use_enemy_pooling: bool = true
## Maximum distance from player to spawn enemies
@export var max_spawn_distance: float = 100.0
## Minimum distance from player to spawn enemies
@export var min_spawn_distance: float = 20.0

@export_group("Enemy Types")
## Available enemy scenes to spawn
@export var enemy_scenes: Array[PackedScene] = []
## Weight for each enemy type (higher = more likely)
@export var enemy_weights: Array[int] = []

# Internal state
var active_enemies: Array[AIEnemyBase] = []
var enemy_pool: Dictionary = {} # Scene path -> Array of pooled enemies
var player_reference: Node3D = null

func _ready() -> void:
	_find_player()
	_setup_enemy_pool()
	
	# Set up spawn points if none provided
	if spawn_points.is_empty():
		_generate_spawn_points()

func _find_player() -> void:
	player_reference = get_tree().get_first_node_in_group("Player")
	if not player_reference:
		push_warning("AI Spawner: No player found in 'Player' group")

func _setup_enemy_pool() -> void:
	if not use_enemy_pooling:
		return
	
	# Pre-instantiate enemies for pooling
	for scene in enemy_scenes:
		if not scene:
			continue
		
		var scene_path = scene.resource_path
		enemy_pool[scene_path] = []
		
		# Create a few instances for each enemy type
		for i in 3:
			var enemy = scene.instantiate()
			enemy_pool[scene_path].append(enemy)
			# Don't add to scene tree yet

func _generate_spawn_points() -> void:
	# Generate spawn points around the spawner
	var point_count = 8
	for i in point_count:
		var angle = (i / float(point_count)) * TAU
		var distance = 15.0
		var point = Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)
		spawn_points.append(global_position + point)

## Spawn a random enemy at a valid spawn point
func spawn_enemy() -> AIEnemyBase:
	if active_enemies.size() >= max_active_enemies:
		return null
	
	if enemy_scenes.is_empty():
		push_error("AI Spawner: No enemy scenes configured")
		return null
	
	var spawn_point = _get_valid_spawn_point()
	if spawn_point == Vector3.ZERO:
		return null # No valid spawn point found
	
	var enemy_scene = _select_enemy_scene()
	if not enemy_scene:
		return null
	
	var enemy = _instantiate_enemy(enemy_scene)
	if not enemy:
		return null
	
	# Position and configure enemy
	enemy.global_position = spawn_point
	enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	
	# Add to scene tree
	get_tree().current_scene.add_child(enemy)
	active_enemies.append(enemy)
	
	enemy_spawned.emit(enemy)
	return enemy

func _get_valid_spawn_point() -> Vector3:
	if not player_reference:
		# If no player, use first spawn point
		return spawn_points[0] if not spawn_points.is_empty() else global_position
	
	# Find spawn points that are at appropriate distance from player
	var valid_points: Array[Vector3] = []
	
	for point in spawn_points:
		var distance = player_reference.global_position.distance_to(point)
		if distance >= min_spawn_distance and distance <= max_spawn_distance:
			# Check if spawn point is clear
			if _is_spawn_point_clear(point):
				valid_points.append(point)
	
	if valid_points.is_empty():
		return Vector3.ZERO
	
	# Return random valid point
	return valid_points[randi() % valid_points.size()]

func _is_spawn_point_clear(point: Vector3) -> bool:
	# Simple check to ensure no obstacles at spawn point
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2, point - Vector3.UP)
	query.collision_mask = 0b11111111 # Check all layers
	
	var result = space_state.intersect_ray(query)
	return not result.is_empty() # Should hit ground

func _select_enemy_scene() -> PackedScene:
	if enemy_scenes.is_empty():
		return null
	
	# Use weights if provided
	if enemy_weights.size() == enemy_scenes.size():
		return _weighted_random_selection()
	
	# Otherwise random selection
	return enemy_scenes[randi() % enemy_scenes.size()]

func _weighted_random_selection() -> PackedScene:
	var total_weight = 0
	for weight in enemy_weights:
		total_weight += weight
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for i in enemy_scenes.size():
		current_weight += enemy_weights[i]
		if random_value < current_weight:
			return enemy_scenes[i]
	
	# Fallback
	return enemy_scenes[0]

func _instantiate_enemy(scene: PackedScene) -> AIEnemyBase:
	var enemy: AIEnemyBase
	
	if use_enemy_pooling:
		var scene_path = scene.resource_path
		if scene_path in enemy_pool and not enemy_pool[scene_path].is_empty():
			enemy = enemy_pool[scene_path].pop_back()
		else:
			enemy = scene.instantiate()
	else:
		enemy = scene.instantiate()
	
	return enemy

func _on_enemy_died(enemy: AIEnemyBase) -> void:
	active_enemies.erase(enemy)
	enemy_destroyed.emit(enemy)
	
	# Return to pool if using pooling
	if use_enemy_pooling and is_instance_valid(enemy):
		var scene_path = enemy.scene_file_path
		if scene_path in enemy_pool:
			enemy.get_parent().remove_child(enemy)
			enemy_pool[scene_path].append(enemy)
		else:
			enemy.queue_free()
	
	# Check if all enemies defeated
	if active_enemies.is_empty():
		all_enemies_defeated.emit()

## Spawn multiple enemies
func spawn_wave(count: int) -> void:
	for i in count:
		spawn_enemy()
		# Small delay between spawns
		await get_tree().create_timer(0.1).timeout
	
	spawn_wave_complete.emit()

## Clean up all active enemies (for level transitions)
func cleanup_all_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

## Get spawn statistics for debugging
func get_spawn_stats() -> Dictionary:
	return {
		"active_enemies": active_enemies.size(),
		"max_enemies": max_active_enemies,
		"pooled_enemies": _count_pooled_enemies(),
		"spawn_points": spawn_points.size()
	}

func _count_pooled_enemies() -> int:
	var count = 0
	for pool in enemy_pool.values():
		count += pool.size()
	return count
