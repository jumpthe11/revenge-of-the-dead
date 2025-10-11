extends Resource

class_name WaveConfig

## Configuration resource for enemy waves
## Defines what enemies spawn in each wave and how

@export_group("Wave Info")
## Wave number/identifier
@export var wave_number: int = 1
## Display name for this wave
@export var wave_name: String = "Wave 1"
## Time delay before this wave starts (seconds)
@export var start_delay: float = 2.0

@export_group("Enemy Composition")
## Enemy scenes to spawn in this wave
@export var enemy_scenes: Array[PackedScene] = []
## How many of each enemy type to spawn
@export var enemy_counts: Array[int] = []
## Optional: Custom spawn weights (higher = more likely to spawn early)
@export var enemy_weights: Array[int] = []

@export_group("Spawn Behavior")
## Total number of enemies in this wave
@export var total_enemies: int = 5
## Time between individual enemy spawns (seconds)
@export var spawn_interval: float = 1.0
## Maximum enemies active at once (0 = no limit)
@export var max_simultaneous: int = 0
## Whether to spawn all enemies at once
@export var spawn_all_at_once: bool = false

@export_group("Wave Progression")
## Whether player must kill all enemies to proceed
@export var must_clear_all: bool = true
## Time after wave clear before next wave (seconds)
@export var clear_delay: float = 3.0
## Reward points for completing this wave
@export var completion_reward: int = 100

@export_group("Special Behaviors")
## Whether this is a boss wave
@export var is_boss_wave: bool = false
## Special effects or modifiers
@export var wave_modifiers: Array[String] = []

## Validate the wave configuration
func validate() -> bool:
	if enemy_scenes.is_empty():
		push_error("WaveConfig: No enemy scenes defined")
		return false
	
	if enemy_counts.size() != enemy_scenes.size():
		push_warning("WaveConfig: Enemy counts don't match enemy scenes, using defaults")
		_fix_enemy_counts()
	
	if total_enemies <= 0:
		total_enemies = _calculate_total_enemies()
	
	return true

func _fix_enemy_counts() -> void:
	enemy_counts.clear()
	for i in enemy_scenes.size():
		enemy_counts.append(1)

func _calculate_total_enemies() -> int:
	var total = 0
	for count in enemy_counts:
		total += count
	return max(total, 1)

## Get a random enemy scene based on weights
func get_weighted_enemy_scene() -> PackedScene:
	if enemy_scenes.is_empty():
		return null
	
	if enemy_weights.size() != enemy_scenes.size():
		# Return random scene if no weights
		return enemy_scenes[randi() % enemy_scenes.size()]
	
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

## Get enemy composition for spawning
func get_spawn_list() -> Array[PackedScene]:
	var spawn_list: Array[PackedScene] = []
	
	for i in enemy_scenes.size():
		var count = enemy_counts[i] if i < enemy_counts.size() else 1
		for j in count:
			spawn_list.append(enemy_scenes[i])
	
	# Shuffle for variety
	spawn_list.shuffle()
	return spawn_list