@icon("res://Player_Controller/scripts/Weapon_State_Machine/weapon_resource_icon.svg")
extends Resource
class_name WeaponStatsModifier

## Weapon Statistics Modifier System
## Handles additive and multiplicative stat modifications for weapons
## Optimized for performance with cached calculated values

signal stats_changed

## Base weapon stats (will be set from WeaponResource)
var base_damage: float = 100.0
var base_fire_rate: float = 600.0  # RPM (Rounds Per Minute)
var base_magazine: int = 30
var base_max_ammo: int = 300
var base_fire_range: float = 1000.0
var base_melee_damage: float = 50.0
var base_reload_time: float = 2.0  # seconds

## Additive modifiers (flat bonuses)
var damage_add: float = 0.0
var fire_rate_add: float = 0.0
var magazine_add: int = 0
var max_ammo_add: int = 0
var fire_range_add: float = 0.0
var melee_damage_add: float = 0.0
var reload_time_add: float = 0.0

## Multiplicative modifiers (percentage bonuses)
var damage_mult: float = 1.0
var fire_rate_mult: float = 1.0
var magazine_mult: float = 1.0
var max_ammo_mult: float = 1.0
var fire_range_mult: float = 1.0
var melee_damage_mult: float = 1.0
var reload_time_mult: float = 1.0

## Cached calculated values (updated when modifiers change)
var final_damage: float = 0.0
var final_fire_rate: float = 30.0
var final_magazine: int = 30
var final_max_ammo: int = 300
var final_fire_range: float = 1000.0
var final_melee_damage: float = 50.0
var final_reload_time: float = 2.0

## Animation speed calculation (for performance)
var animation_speed_multiplier: float = 1.0
var fire_interval: float = 2.0  # Time between shots in seconds

## Initialize with weapon resource data
func initialize_from_weapon(weapon: WeaponResource) -> void:
	if not weapon:
		push_error("WeaponStatsModifier: Cannot initialize with null weapon resource")
		return
	
	base_damage = weapon.damage
	base_magazine = weapon.magazine
	base_max_ammo = weapon.max_ammo
	base_fire_range = weapon.fire_range
	base_melee_damage = weapon.melee_damage
	
	# Use weapon's fire_rate if available, otherwise default to 30 RPM
	base_fire_rate = weapon.fire_rate if "fire_rate" in weapon else 30.0
	
	base_reload_time = 2.0
	
	recalculate_stats()

## Recalculate all final stats (call this when modifiers change)
func recalculate_stats() -> void:
	# Calculate final stats: (base + additive) * multiplicative
	final_damage = (base_damage + damage_add) * damage_mult
	final_fire_rate = max((base_fire_rate + fire_rate_add) * fire_rate_mult, 1.0)  # Min 1 RPM
	final_magazine = max(int((base_magazine + magazine_add) * magazine_mult), 1)  # Min 1 round
	final_max_ammo = max(int((base_max_ammo + max_ammo_add) * max_ammo_mult), 0)
	final_fire_range = max((base_fire_range + fire_range_add) * fire_range_mult, 1.0)
	final_melee_damage = max((base_melee_damage + melee_damage_add) * melee_damage_mult, 0.0)
	final_reload_time = max((base_reload_time + reload_time_add) * reload_time_mult, 0.1)  # Min 0.1 seconds
	
	# Calculate animation speed and fire interval
	calculate_animation_speed()
	
	# Emit signal so listeners (like weapon state machine) know stats changed
	stats_changed.emit()

## Calculate animation speed based on fire rate (optimized for performance)
func calculate_animation_speed() -> void:
	# Convert RPM to shots per second
	var shots_per_second = max(final_fire_rate / 60.0, 0.01)  # Prevent division by zero
	fire_interval = 1.0 / shots_per_second
	
	# Scale animation speed: 30 RPM = 1.0x speed, 120+ RPM = 2.0x speed
	# This prevents extremely fast animations at very high fire rates
	var normalized_fire_rate = max(final_fire_rate / 30.0, 0.1)  # 30 RPM = 1.0, min 0.1
	animation_speed_multiplier = min(normalized_fire_rate, 2.0)  # Cap at 2.0x speed

## Add temporary modifier (useful for buffs/debuffs)
func add_temporary_modifier(stat_name: String, additive: float = 0.0, multiplicative: float = 1.0) -> void:
	match stat_name:
		"damage":
			damage_add += additive
			damage_mult *= multiplicative
		"fire_rate":
			fire_rate_add += additive
			fire_rate_mult *= multiplicative
		"magazine":
			magazine_add += int(additive)
			magazine_mult *= multiplicative
		"max_ammo":
			max_ammo_add += int(additive)
			max_ammo_mult *= multiplicative
		"fire_range":
			fire_range_add += additive
			fire_range_mult *= multiplicative
		"melee_damage":
			melee_damage_add += additive
			melee_damage_mult *= multiplicative
		"reload_time":
			reload_time_add += additive
			reload_time_mult *= multiplicative
	
	recalculate_stats()

## Remove all modifiers (reset to base stats)
func reset_modifiers() -> void:
	damage_add = 0.0
	fire_rate_add = 0.0
	magazine_add = 0
	max_ammo_add = 0
	fire_range_add = 0.0
	melee_damage_add = 0.0
	reload_time_add = 0.0
	
	damage_mult = 1.0
	fire_rate_mult = 1.0
	magazine_mult = 1.0
	max_ammo_mult = 1.0
	fire_range_mult = 1.0
	melee_damage_mult = 1.0
	reload_time_mult = 1.0
	
	recalculate_stats()

## Get current fire rate in shots per second (for performance calculations)
func get_shots_per_second() -> float:
	return final_fire_rate / 60.0

## Get time between shots in seconds
func get_fire_interval() -> float:
	return fire_interval

## Get animation speed multiplier for current fire rate
func get_animation_speed() -> float:
	return animation_speed_multiplier

## Debug function to print current stats
func print_stats() -> void:
	print("=== Weapon Stats ===")
	print("Damage: %.1f (base: %.1f)" % [final_damage, base_damage])
	print("Fire Rate: %.1f RPM (base: %.1f)" % [final_fire_rate, base_fire_rate])
	print("Magazine: %d (base: %d)" % [final_magazine, base_magazine])
	print("Max Ammo: %d (base: %d)" % [final_max_ammo, base_max_ammo])
	print("Fire Range: %.1f (base: %.1f)" % [final_fire_range, base_fire_range])
	print("Animation Speed: %.2fx" % animation_speed_multiplier)
	print("Fire Interval: %.3fs" % fire_interval)
