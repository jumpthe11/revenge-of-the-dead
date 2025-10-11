@icon("res://Player_Controller/scripts/Weapon_State_Machine/weapon_resource_icon.svg")
extends Resource

class_name AIWeaponResource

## Simplified weapon resource for AI enemies
## Focuses on performance and essential stats only

@export_group("Basic Stats")
## Weapon identifier for AI type
@export var weapon_name: String
## Base damage per shot
@export var damage: int = 10
## Fire rate in seconds between shots
@export var fire_rate: float = 1.0
## Maximum effective range
@export var max_range: float = 50.0
## Minimum engagement range
@export var min_range: float = 2.0

@export_group("Behavior")
## Whether this weapon requires line of sight
@export var requires_line_of_sight: bool = true
## Whether weapon fires in bursts
@export var burst_fire: bool = false
## Number of shots in a burst (if burst_fire is true)
@export var burst_count: int = 3
## Time between bursts
@export var burst_cooldown: float = 2.0
## Weapon spread in degrees
@export var accuracy_spread: float = 5.0

@export_group("Projectile")
## The projectile scene to instantiate
@export var projectile_scene: PackedScene
## Projectile speed (for physics projectiles)
@export var projectile_speed: float = 100.0
## Whether projectile uses hitscan or physics
@export_enum("Hitscan", "Physics") var projectile_type: String = "Hitscan"

@export_group("Performance")
## Maximum number of projectiles this weapon can have active
@export var max_active_projectiles: int = 5
## Whether to pool projectiles for performance
@export var use_projectile_pooling: bool = true

## Get the optimal engagement range for this weapon
func get_optimal_range() -> float:
	return (max_range + min_range) / 2.0

## Check if target is within effective range
func is_in_range(distance: float) -> bool:
	return distance >= min_range and distance <= max_range

## Calculate damage based on distance (damage falloff)
func calculate_damage_at_distance(distance: float) -> int:
	if distance > max_range:
		return 0
	
	# Linear damage falloff from optimal range to max range
	var optimal_range = get_optimal_range()
	if distance <= optimal_range:
		return damage
	
	var falloff_factor = 1.0 - ((distance - optimal_range) / (max_range - optimal_range)) * 0.5
	return int(damage * falloff_factor)
