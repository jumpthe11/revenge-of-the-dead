# AI Wave System - Usage Guide

## 🚀 Quick Start

### Method 1: Use the Complete Wave System Scene (Recommended)
1. **Add Wave System to Your Level**:
   - Drag `AI_System/scenes/wave_system.tscn` into your level
   - Add `AI_System/scenes/ai_spawner.tscn` nodes around your level
   - Connect the spawners to the Wave Manager

2. **Set Up Spawners**:
   - In the WaveSystem node, add your spawners to the "Spawners" array
   - Position spawners strategically around your level

3. **Start the Waves**:
   - Run your scene
   - Click "Start Waves" button or call `wave_manager.start_waves()` in code

### Method 2: Custom Setup
If you want more control, you can set up the system manually:

## 📋 Step-by-Step Setup

### 1. Create a Wave Manager
```gdscript
# In your level script
@onready var wave_manager = WaveManager.new()
add_child(wave_manager)
```

### 2. Create and Configure AI Spawners
```gdscript
# Create spawner
var spawner = preload("res://AI_System/scenes/ai_spawner.tscn").instantiate()
add_child(spawner)
spawner.global_position = Vector3(0, 0, 0)

# Configure spawner settings
spawner.max_active_enemies = 5
spawner.use_enemy_pooling = true
spawner.enemy_scenes = [
	preload("res://AI_System/scenes/rifle_soldier.tscn"),
	preload("res://AI_System/scenes/shotgun_rusher.tscn")
]

# Add to wave manager
wave_manager.spawners.append(spawner)
```

### 3. Create Wave Configurations
You can either use the existing `.tres` files or create them in code:

```gdscript
# Create wave config in code
var wave_config = WaveConfig.new()
wave_config.wave_number = 1
wave_config.wave_name = "First Wave"
wave_config.enemy_scenes = [
	preload("res://AI_System/scenes/rifle_soldier.tscn"),
	preload("res://AI_System/scenes/shotgun_rusher.tscn")
]
wave_config.enemy_counts = [3, 2]
wave_config.total_enemies = 5
wave_config.spawn_interval = 2.0

wave_manager.wave_configs.append(wave_config)
```

### 4. Start the Wave System
```gdscript
# Start all waves
wave_manager.start_waves()

# Or start a specific wave
wave_manager._start_wave(wave_config)
```

## 🎛️ Wave Configuration Options

### Wave Settings
```gdscript
wave_config.wave_number = 1              # Wave identifier
wave_config.wave_name = "First Contact"  # Display name
wave_config.start_delay = 3.0            # Delay before wave starts
wave_config.total_enemies = 5            # Total enemies in wave
wave_config.spawn_interval = 2.0         # Time between spawns
wave_config.max_simultaneous = 3         # Max enemies at once
wave_config.spawn_all_at_once = false    # All enemies at once?
wave_config.must_clear_all = true        # Must kill all to proceed?
wave_config.clear_delay = 4.0            # Delay after wave clear
wave_config.completion_reward = 100      # Points for completing wave
```

### Enemy Composition
```gdscript
# Define which enemies spawn
wave_config.enemy_scenes = [
	preload("res://AI_System/scenes/rifle_soldier.tscn"),
	preload("res://AI_System/scenes/shotgun_rusher.tscn"),
	preload("res://AI_System/scenes/melee_brute.tscn")
]

# How many of each enemy type
wave_config.enemy_counts = [3, 2, 1]  # 3 rifles, 2 shotguns, 1 brute

# Optional spawn weights (higher = more likely to spawn first)
wave_config.enemy_weights = [3, 2, 1]
```

## 🎮 Spawner Configuration

### Basic Settings
```gdscript
spawner.max_active_enemies = 10      # Max enemies active at once
spawner.use_enemy_pooling = true     # Enable object pooling
spawner.max_spawn_distance = 50.0    # Max distance from player to spawn
spawner.min_spawn_distance = 15.0    # Min distance from player to spawn
```

### Enemy Configuration
```gdscript
spawner.enemy_scenes = [scene1, scene2]  # Available enemy types
spawner.enemy_weights = [3, 1]           # Spawn probability weights
```

### Custom Spawn Points
```gdscript
# Define custom spawn points
spawner.spawn_points = [
	Vector3(10, 0, 10),
	Vector3(-10, 0, 10),
	Vector3(0, 0, -10)
]
```

## 🔧 Scripting Examples

### Connect to Wave Events
```gdscript
func _ready():
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	wave_manager.enemy_count_changed.connect(_on_enemy_count_changed)

func _on_wave_started(wave_number: int, wave_name: String):
	print("Wave started: ", wave_name)
	# Play wave start sound, show UI, etc.

func _on_wave_completed(wave_number: int, reward: int):
	print("Wave completed! Reward: ", reward)
	# Add points, show completion message

func _on_all_waves_completed():
	print("All waves completed!")
	# End game, show victory screen

func _on_enemy_count_changed(remaining: int, total: int):
	print("Enemies remaining: ", remaining, "/", total)
	# Update UI counter
```

### Manual Wave Control
```gdscript
# Skip to next wave
wave_manager.skip_to_next_wave()

# Stop all waves
wave_manager.stop_waves()

# Get wave statistics
var stats = wave_manager.get_wave_stats()
print("Current wave: ", stats.current_wave)
print("Enemies remaining: ", stats.enemies_remaining)
```

### Spawn Individual Enemies
```gdscript
# Spawn a specific enemy
var enemy = spawner.spawn_enemy()
if enemy:
	print("Enemy spawned: ", enemy.name)

# Spawn multiple enemies
spawner.spawn_wave(5)  # Spawn 5 enemies with delays
```

## 🎯 Enemy Types Reference

### Rifle Soldier
- **Role**: Medium-range precision fighter
- **Health**: 75 HP
- **Speed**: 4.0 units/sec
- **Range**: 35m detection, 40m weapon range
- **Behavior**: Maintains distance, uses burst fire, strafing movement

### Shotgun Rusher
- **Role**: Aggressive close-range fighter  
- **Health**: 60 HP
- **Speed**: 6.0 units/sec (rushes at 1.5x when close)
- **Range**: 30m detection, 12m weapon range
- **Behavior**: Fast approach, double-tap attacks, circle strafing

### Melee Brute
- **Role**: Tank and close-combat specialist
- **Health**: 150 HP (1.5x base health)
- **Speed**: 3.5 units/sec (2x when charging)
- **Range**: 40m detection, 3m attack range
- **Behavior**: Charging attacks, knockback, death explosion

## 🔧 Performance Tips

### Optimization Settings
```gdscript
# For better performance with many enemies:
spawner.max_active_enemies = 8        # Limit concurrent enemies
spawner.use_enemy_pooling = true      # Enable object pooling
wave_manager.distribute_spawning = true  # Balance across spawners

# Wave configuration for performance:
wave_config.max_simultaneous = 4     # Limit simultaneous enemies
wave_config.spawn_interval = 1.5     # Don't spawn too frequently
```

### Memory Management
- **Object Pooling**: Automatically enabled, reuses enemy instances
- **Projectile Pooling**: Each AI weapon controller pools projectiles
- **Automatic Cleanup**: Enemies and projectiles are cleaned up automatically
- **Staggered Updates**: AI systems update on different frames

## 🐛 Troubleshooting

### Common Issues

**"No valid spawners assigned!"**
- Make sure you've added AISpawner nodes to the spawners array in WaveManager

**Enemies not spawning**
- Check that enemy_scenes array is populated in wave config
- Verify spawn points are not too close/far from player
- Ensure max_active_enemies limit isn't reached

**AI not targeting player**
- Make sure player node is in the "Player" group
- Check detection_range values on AI enemies
- Verify line-of-sight isn't blocked

**Performance issues**
- Reduce max_active_enemies
- Increase spawn_interval
- Enable use_enemy_pooling
- Limit max_simultaneous enemies per wave

### Debug Information
```gdscript
# Get spawner statistics
var stats = spawner.get_spawn_stats()
print("Active enemies: ", stats.active_enemies)
print("Pooled enemies: ", stats.pooled_enemies)

# Get wave manager statistics  
var wave_stats = wave_manager.get_wave_stats()
print("Current wave: ", wave_stats.current_wave)
print("Is active: ", wave_stats.is_active)
```

## 📝 Example Level Setup

Here's a complete example of setting up the wave system in a level:

```gdscript
extends Node3D

@onready var wave_manager: WaveManager
@onready var spawner1: AISpawner
@onready var spawner2: AISpawner

func _ready():
    # Set up wave system
    setup_wave_system()
    
    # Start waves after a delay
    await get_tree().create_timer(2.0).timeout
    wave_manager.start_waves()

func setup_wave_system():
    # Create wave manager
    wave_manager = WaveManager.new()
    add_child(wave_manager)
    
    # Set up spawners
    spawner1 = preload("res://AI_System/scenes/ai_spawner.tscn").instantiate()
    spawner2 = preload("res://AI_System/scenes/ai_spawner.tscn").instantiate()
    
    add_child(spawner1)
    add_child(spawner2)
    
    spawner1.global_position = Vector3(20, 0, 0)
    spawner2.global_position = Vector3(-20, 0, 0)
    
    # Connect spawners to wave manager
    wave_manager.spawners = [spawner1, spawner2]
    
    # Load wave configurations
    wave_manager.wave_configs = [
        preload("res://AI_System/resources/wave_1_config.tres"),
        preload("res://AI_System/resources/wave_2_config.tres"),
        preload("res://AI_System/resources/wave_boss_config.tres")
    ]
    
    # Configure wave manager
    wave_manager.loop_waves = false
    wave_manager.distribute_spawning = true
    
    # Connect events
    wave_manager.wave_completed.connect(_on_wave_completed)
    wave_manager.all_waves_completed.connect(_on_all_waves_completed)

func _on_wave_completed(wave_number: int, reward: int):
    print("Wave ", wave_number, " completed! Reward: ", reward)

func _on_all_waves_completed():
    print("Victory! All waves defeated!")
```

This system provides a complete, performance-optimized wave-based enemy spawning system that's easy to use and extend!
