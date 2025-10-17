extends Node
class_name DebugWeaponCheats

## Debug/Cheat script for testing bullet trails and weapon systems
## Press F10 to toggle cheats on/off

@export var weapon_state_machine: Node3D  ## Drag Weapon_State_Machine here
@export var player_character: CharacterBody3D  ## Drag Player node here
@export var enable_on_start: bool = false

# Cheat multipliers
@export_group("Weapon Stat Multipliers")
@export var fire_rate_multiplier: float = 10.0  ## 10x faster fire rate
@export var damage_multiplier: float = 2.0  ## 2x damage
@export var infinite_ammo: bool = true
@export var no_reload: bool = true
@export var bypass_animations: bool = true  ## Directly spawn bullets for extreme fire rates

@export_group("Player Stat Multipliers")
@export var health_multiplier: float = 10.0  ## 10x health
@export var speed_multiplier: float = 2.0  ## 2x movement speed
@export var god_mode: bool = true  ## No damage

var cheats_enabled: bool = false
var original_weapon_stats: Dictionary = {}
var original_player_stats: Dictionary = {}
var rapid_fire_timer: Timer

func _ready() -> void:
	print("DebugWeaponCheats: Initializing...")
	
	if not weapon_state_machine:
		push_error("DebugWeaponCheats: weapon_state_machine not assigned!")
		return
	
	if not player_character:
		push_error("DebugWeaponCheats: player_character not assigned!")
		return
	
	# Setup rapid fire timer
	rapid_fire_timer = Timer.new()
	rapid_fire_timer.name = "RapidFireTimer"
	rapid_fire_timer.wait_time = 0.01  # 100 shots per second
	rapid_fire_timer.one_shot = false  # Keep firing
	add_child(rapid_fire_timer)
	rapid_fire_timer.timeout.connect(_on_rapid_fire)
	print("DebugWeaponCheats: Timer created - ", rapid_fire_timer)
	
	if enable_on_start:
		call_deferred("enable_cheats")  # Defer to ensure everything is ready
	
	print("Debug Weapon Cheats loaded! Press F10 to toggle")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		toggle_cheats()

func toggle_cheats() -> void:
	if cheats_enabled:
		disable_cheats()
	else:
		enable_cheats()

func enable_cheats() -> void:
	print("DebugWeaponCheats: enable_cheats() called")
	
	if not weapon_state_machine:
		print("ERROR: weapon_state_machine is null")
		return
	
	if not player_character:
		print("ERROR: player_character is null")
		return
	
	cheats_enabled = true
	print("=== CHEATS ENABLED ===")
	print("[WEAPON] Fire Rate: x", fire_rate_multiplier)
	print("[WEAPON] Damage: x", damage_multiplier)
	print("[WEAPON] Infinite Ammo: ", infinite_ammo)
	print("[WEAPON] No Reload: ", no_reload)
	print("[PLAYER] Health: x", health_multiplier)
	print("[PLAYER] Speed: x", speed_multiplier)
	print("[PLAYER] God Mode: ", god_mode)
	
	# Apply stat modifiers to all weapons
	for weapon_slot in weapon_state_machine.weapon_stack:
		if not weapon_slot:
			continue
		
		var stats: WeaponStatsModifier = weapon_slot.get_meta("weapon_stats", null)
		if not stats:
			continue
		
		# Store original stats for restoration
		if not original_weapon_stats.has(weapon_slot):
			original_weapon_stats[weapon_slot] = {
				"fire_rate": stats.base_fire_rate,
				"damage": stats.base_damage
			}
		
		# Apply fire rate boost
		stats.add_temporary_modifier("fire_rate", 0.0, fire_rate_multiplier)
		
		# Apply damage boost
		stats.add_temporary_modifier("damage", 0.0, damage_multiplier)
		
		print("Boosted: ", weapon_slot.weapon.weapon_name)
		stats.print_stats()
	
	# Connect to ammo updates for infinite ammo
	if infinite_ammo and not weapon_state_machine.update_ammo.is_connected(_on_infinite_ammo):
		weapon_state_machine.update_ammo.connect(_on_infinite_ammo)
	
	# Buff player stats
	_apply_player_buffs()
	
	# Update rapid fire rate based on current weapon's actual fire rate
	if bypass_animations and fire_rate_multiplier > 5.0 and rapid_fire_timer:
		var current_weapon = weapon_state_machine.current_weapon_slot
		if current_weapon:
			var current_stats: WeaponStatsModifier = current_weapon.get_meta("weapon_stats", null)
			if current_stats:
				# Use actual weapon base fire rate
				var base_rpm = current_stats.base_fire_rate
				var target_rpm = base_rpm * fire_rate_multiplier
				var shots_per_second = target_rpm / 60.0
				rapid_fire_timer.wait_time = max(0.001, 1.0 / shots_per_second)  # Min 0.001s
				print("Rapid fire: ", shots_per_second, " shots/sec (base: ", base_rpm, " RPM)")

func disable_cheats() -> void:
	if not weapon_state_machine:
		return
	
	cheats_enabled = false
	print("=== CHEATS DISABLED ===")
	
	# Restore player stats
	_restore_player_stats()
	
	# Restore original weapon stats
	for weapon_slot in weapon_state_machine.weapon_stack:
		if not weapon_slot or not original_weapon_stats.has(weapon_slot):
			continue
		
		var stats: WeaponStatsModifier = weapon_slot.get_meta("weapon_stats", null)
		if not stats:
			continue
		
		# Clear all modifiers
		stats.reset_modifiers()
		
		print("Restored: ", weapon_slot.weapon.weapon_name)
		stats.print_stats()
	
	# Disconnect infinite ammo
	if weapon_state_machine.update_ammo.is_connected(_on_infinite_ammo):
		weapon_state_machine.update_ammo.disconnect(_on_infinite_ammo)
	
	# Stop rapid fire
	if rapid_fire_timer and rapid_fire_timer.timeout.is_connected(_on_rapid_fire):
		rapid_fire_timer.stop()

func _on_infinite_ammo(ammo_data: Array) -> void:
	if not cheats_enabled or not infinite_ammo:
		return
	
	var current_weapon = weapon_state_machine.current_weapon_slot
	if not current_weapon:
		return
	
	# Refill ammo instantly
	current_weapon.current_ammo = current_weapon.weapon.magazine
	current_weapon.reserve_ammo = current_weapon.weapon.max_ammo

func _process(_delta: float) -> void:
	if not cheats_enabled:
		return
	
	var current_weapon = weapon_state_machine.current_weapon_slot
	if not current_weapon:
		return
	
	# Auto-cancel reload animations
	if no_reload:
		var anim_player = weapon_state_machine.animation_player
		if anim_player and anim_player.current_animation == current_weapon.weapon.reload_animation:
			anim_player.stop()
			current_weapon.current_ammo = current_weapon.weapon.magazine
	
	# Handle rapid fire with animation bypass
	if bypass_animations and fire_rate_multiplier > 5.0 and rapid_fire_timer:
		if Input.is_action_pressed("Shoot"):
			if not rapid_fire_timer.is_stopped():
				return  # Already firing
			rapid_fire_timer.start()
		else:
			rapid_fire_timer.stop()

func _on_rapid_fire() -> void:
	if not cheats_enabled or not bypass_animations:
		return
	
	var current_weapon = weapon_state_machine.current_weapon_slot
	if not current_weapon or not current_weapon.weapon:
		return
	
	# Directly spawn projectile without animation
	var spread = Vector2.ZERO
	if current_weapon.weapon.weapon_spray:
		var spray_profile = weapon_state_machine.spray_profiles.get(current_weapon.weapon.weapon_name)
		if spray_profile:
			weapon_state_machine._count += 1
			spread = spray_profile.Get_Spray(weapon_state_machine._count, current_weapon.weapon.magazine)
	
	weapon_state_machine.load_projectile(spread)
	
	# Don't emit hit signal here - the projectile will emit it when it actually hits something

func _apply_player_buffs() -> void:
	if not player_character:
		return
	
	# Store original player stats
	if original_player_stats.is_empty():
		original_player_stats = {
			"max_health": player_character.max_health,
			"current_health": player_character.current_health,
			"base_speed": player_character.base_speed,
			"sprint_speed": player_character.sprint_speed,
			"walk_speed": player_character.walk_speed
		}
	
	# Apply health buff
	player_character.max_health *= health_multiplier
	player_character.current_health = player_character.max_health  # Full heal
	
	# Apply speed buffs
	player_character.base_speed *= speed_multiplier
	player_character._speed *= speed_multiplier
	player_character.sprint_speed *= speed_multiplier
	player_character.walk_speed *= speed_multiplier
	
	print("[PLAYER] Health: ", player_character.current_health, "/", player_character.max_health)
	print("[PLAYER] Speed: ", player_character.base_speed)
	
	# Connect to damage for god mode
	if god_mode and not player_character.player_damaged.is_connected(_on_god_mode_damage):
		player_character.player_damaged.connect(_on_god_mode_damage)

func _restore_player_stats() -> void:
	if not player_character or original_player_stats.is_empty():
		return
	
	# Restore original stats
	player_character.max_health = original_player_stats["max_health"]
	player_character.current_health = original_player_stats["current_health"]
	player_character.base_speed = original_player_stats["base_speed"]
	player_character._speed = original_player_stats["base_speed"]
	player_character.sprint_speed = original_player_stats["sprint_speed"]
	player_character.walk_speed = original_player_stats["walk_speed"]
	
	original_player_stats.clear()
	
	print("[PLAYER] Stats restored")
	
	# Disconnect god mode
	if player_character.player_damaged.is_connected(_on_god_mode_damage):
		player_character.player_damaged.disconnect(_on_god_mode_damage)

func _on_god_mode_damage(_current_health: float, _max_health: float) -> void:
	if not cheats_enabled or not god_mode:
		return
	
	# Instantly refill health
	player_character.current_health = player_character.max_health
	print("[GOD MODE] Damage negated")
