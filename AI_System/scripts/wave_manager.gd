extends Node

class_name WaveManager

## Master wave system that manages enemy spawning across multiple spawners
## Handles wave progression, player feedback, and game state

signal wave_started(wave_number: int, wave_name: String)
signal wave_completed(wave_number: int, reward: int)
signal wave_failed
signal all_waves_completed
signal enemy_count_changed(remaining: int, total: int)

@export_group("Wave Settings")
## Array of wave configurations
@export var wave_configs: Array[WaveConfig] = []
## Whether waves loop after completion
@export var loop_waves: bool = false
## Difficulty scaling per loop (1.0 = no scaling)
@export var difficulty_multiplier: float = 1.2

@export_group("Spawners")
## AI Spawners to use for enemy spawning
@export var spawners: Array[AISpawner] = []
## Whether to distribute enemies across all spawners
@export var distribute_spawning: bool = true

@export_group("UI Elements")
## Optional UI label for wave info
@export var wave_label: Label = null
## Optional UI label for enemy count
@export var enemy_count_label: Label = null
## Optional UI for wave progress
@export var wave_progress_bar: ProgressBar = null

# Internal state
var current_wave_index: int = 0
var current_loop: int = 0
var is_wave_active: bool = false
var total_enemies_spawned: int = 0
var enemies_remaining: int = 0
var current_wave_config: WaveConfig = null
var spawn_timer: Timer
var wave_delay_timer: Timer
var active_spawners: Array[AISpawner] = []

func _ready() -> void:
	_setup_timers()
	_validate_spawners()
	_connect_spawner_signals()
	
	if not wave_configs.is_empty():
		_prepare_first_wave()

func _setup_timers() -> void:
	# Spawn interval timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_next_enemy)
	add_child(spawn_timer)
	
	# Wave delay timer
	wave_delay_timer = Timer.new()
	wave_delay_timer.one_shot = true
	wave_delay_timer.timeout.connect(_start_current_wave)
	add_child(wave_delay_timer)

func _validate_spawners() -> void:
	# Remove invalid spawners
	spawners = spawners.filter(func(spawner): return is_instance_valid(spawner))
	
	if spawners.is_empty():
		push_error("WaveManager: No valid spawners assigned!")
		return
	
	# Set up spawners for wave management
	for spawner in spawners:
		spawner.use_enemy_pooling = true  # Enable pooling for performance
		active_spawners.append(spawner)

func _connect_spawner_signals() -> void:
	for spawner in spawners:
		if spawner.enemy_destroyed.is_connected(_on_enemy_defeated):
			continue
		spawner.enemy_destroyed.connect(_on_enemy_defeated)

func _prepare_first_wave() -> void:
	if wave_configs.is_empty():
		return
	
	current_wave_config = wave_configs[0]
	_update_ui()
	
	print("Wave Manager: Ready. Press 'start_waves()' to begin.")

## Start the wave system
func start_waves() -> void:
	if wave_configs.is_empty():
		push_error("WaveManager: No wave configurations!")
		return
	
	if is_wave_active:
		return
	
	current_wave_index = 0
	current_loop = 0
	_start_wave(wave_configs[current_wave_index])

func _start_wave(wave_config: WaveConfig) -> void:
	if not wave_config.validate():
		push_error("WaveManager: Invalid wave configuration!")
		return
	
	current_wave_config = wave_config
	is_wave_active = true
	
	# Apply difficulty scaling for loops
	if current_loop > 0:
		_apply_difficulty_scaling(wave_config)
	
	print("Starting ", wave_config.wave_name)
	wave_started.emit(wave_config.wave_number, wave_config.wave_name)
	
	# Set up spawning
	total_enemies_spawned = 0
	enemies_remaining = wave_config.total_enemies
	_update_ui()
	
	# Configure spawners for this wave
	_configure_spawners_for_wave(wave_config)
	
	# Start spawning after delay
	if wave_config.start_delay > 0:
		wave_delay_timer.wait_time = wave_config.start_delay
		wave_delay_timer.start()
	else:
		_start_current_wave()

func _start_current_wave() -> void:
	if not current_wave_config:
		return
	
	if current_wave_config.spawn_all_at_once:
		_spawn_entire_wave()
	else:
		_start_incremental_spawning()

func _configure_spawners_for_wave(wave_config: WaveConfig) -> void:
	var spawn_list = wave_config.get_spawn_list()
	
	for spawner in active_spawners:
		spawner.enemy_scenes = wave_config.enemy_scenes
		spawner.enemy_weights = wave_config.enemy_weights if not wave_config.enemy_weights.is_empty() else []
		
		# Set max active based on wave config
		if wave_config.max_simultaneous > 0:
			spawner.max_active_enemies = wave_config.max_simultaneous
		
		# Clear any existing enemies
		spawner.cleanup_all_enemies()

func _start_incremental_spawning() -> void:
	if not current_wave_config:
		return
	
	spawn_timer.wait_time = current_wave_config.spawn_interval
	spawn_timer.start()

var spawn_list: Array[PackedScene] = []
var spawn_index: int = 0

func _spawn_next_enemy() -> void:
	if not current_wave_config or total_enemies_spawned >= current_wave_config.total_enemies:
		spawn_timer.stop()
		return
	
	# Initialize spawn list if needed
	if spawn_list.is_empty():
		spawn_list = current_wave_config.get_spawn_list()
		spawn_index = 0
	
	# Get next enemy to spawn
	var enemy_scene = spawn_list[spawn_index] if spawn_index < spawn_list.size() else current_wave_config.get_weighted_enemy_scene()
	
	# Select spawner
	var spawner = _select_spawner_for_enemy()
	if not spawner:
		return
	
	# Try to spawn
	var enemy = _spawn_enemy_from_scene(spawner, enemy_scene)
	if enemy:
		total_enemies_spawned += 1
		spawn_index += 1
		_update_ui()
	
	# Check if we've spawned all enemies
	if total_enemies_spawned >= current_wave_config.total_enemies:
		spawn_timer.stop()

func _spawn_entire_wave() -> void:
	if not current_wave_config:
		return
	
	var spawn_list = current_wave_config.get_spawn_list()
	
	for enemy_scene in spawn_list:
		var spawner = _select_spawner_for_enemy()
		if spawner:
			_spawn_enemy_from_scene(spawner, enemy_scene)
			total_enemies_spawned += 1
	
	_update_ui()

func _select_spawner_for_enemy() -> AISpawner:
	if active_spawners.is_empty():
		return null
	
	if distribute_spawning:
		# Find spawner with least enemies
		var best_spawner: AISpawner = null
		var min_enemies = 999999
		
		for spawner in active_spawners:
			if spawner.active_enemies.size() < min_enemies:
				min_enemies = spawner.active_enemies.size()
				best_spawner = spawner
		
		return best_spawner
	else:
		# Use random spawner
		return active_spawners[randi() % active_spawners.size()]

func _spawn_enemy_from_scene(spawner: AISpawner, enemy_scene: PackedScene) -> AIEnemyBase:
	# Temporarily override spawner's enemy scenes
	var original_scenes = spawner.enemy_scenes.duplicate()
	spawner.enemy_scenes = [enemy_scene]
	
	var enemy = spawner.spawn_enemy()
	
	# Restore original scenes
	spawner.enemy_scenes = original_scenes
	
	return enemy

func _on_enemy_defeated(enemy: AIEnemyBase) -> void:
	enemies_remaining = max(0, enemies_remaining - 1)
	_update_ui()
	
	enemy_count_changed.emit(enemies_remaining, current_wave_config.total_enemies if current_wave_config else 0)
	
	# Check if wave is complete
	if enemies_remaining <= 0 and current_wave_config.must_clear_all:
		_complete_current_wave()

func _complete_current_wave() -> void:
	if not is_wave_active:
		return
	
	is_wave_active = false
	spawn_timer.stop()
	
	print("Wave ", current_wave_config.wave_name, " completed!")
	wave_completed.emit(current_wave_config.wave_number, current_wave_config.completion_reward)
	
	# Progress to next wave
	current_wave_index += 1
	
	if current_wave_index >= wave_configs.size():
		# End of waves
		if loop_waves:
			current_wave_index = 0
			current_loop += 1
			print("Starting loop ", current_loop + 1)
		else:
			all_waves_completed.emit()
			return
	
	# Start next wave after delay
	await get_tree().create_timer(current_wave_config.clear_delay).timeout
	_start_wave(wave_configs[current_wave_index])

func _apply_difficulty_scaling(wave_config: WaveConfig) -> void:
	var scale = pow(difficulty_multiplier, current_loop)
	wave_config.total_enemies = int(wave_config.total_enemies * scale)
	
	# Scale enemy counts too
	for i in wave_config.enemy_counts.size():
		wave_config.enemy_counts[i] = int(wave_config.enemy_counts[i] * scale)

func _update_ui() -> void:
	if wave_label and current_wave_config:
		wave_label.text = current_wave_config.wave_name
	
	if enemy_count_label:
		enemy_count_label.text = "Enemies: %d" % enemies_remaining
	
	if wave_progress_bar and current_wave_config:
		var progress = float(current_wave_config.total_enemies - enemies_remaining) / float(current_wave_config.total_enemies)
		wave_progress_bar.value = progress * 100

## Manually trigger next wave (for testing)
func skip_to_next_wave() -> void:
	if is_wave_active:
		_complete_current_wave()

## Stop all waves and cleanup
func stop_waves() -> void:
	is_wave_active = false
	spawn_timer.stop()
	wave_delay_timer.stop()
	
	# Clean up all spawners
	for spawner in active_spawners:
		spawner.cleanup_all_enemies()

## Get current wave statistics
func get_wave_stats() -> Dictionary:
	return {
		"current_wave": current_wave_index + 1,
		"total_waves": wave_configs.size(),
		"current_loop": current_loop,
		"enemies_remaining": enemies_remaining,
		"enemies_spawned": total_enemies_spawned,
		"is_active": is_wave_active
	}