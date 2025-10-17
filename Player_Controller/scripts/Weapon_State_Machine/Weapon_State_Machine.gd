extends Node3D

signal weapon_changed
signal update_ammo
signal update_weapon_stack
signal hit_successfull
signal add_signal_to_hud

signal connect_weapon_to_hud
signal weapon_stats_updated(stats: WeaponStatsModifier)

@export var animation_player: AnimationPlayer
@export var melee_hitbox: ShapeCast3D
@export var max_weapons: int
@onready var bullet_point = get_node("%BulletPoint")
@onready var debug_bullet = preload("res://Player_Controller/Spawnable_Objects/hit_debug.tscn")

var next_weapon: WeaponSlot

#The List of All Available weapons in the game
var spray_profiles: Dictionary = {}
var _count = 0
var shot_tween
@export var weapon_stack:Array[WeaponSlot] #An Array of weapons currently in possesion by the player
var current_weapon_slot: WeaponSlot = null

## Stats modifier system for current weapon
var weapon_stats: WeaponStatsModifier = null
var fire_rate_timer: Timer = null

## Called when weapon stats change (from modifiers, buffs, etc)
func _on_weapon_stats_changed() -> void:
	if weapon_stats:
		# Update fire rate timer with new interval
		fire_rate_timer.wait_time = weapon_stats.get_fire_interval()
		# Notify HUD
		weapon_stats_updated.emit(weapon_stats)

func _ready() -> void:
	# Initialize fire rate timer
	fire_rate_timer = Timer.new()
	fire_rate_timer.wait_time = 2.0  # Default fire interval
	fire_rate_timer.one_shot = true
	add_child(fire_rate_timer)
	
	if weapon_stack.is_empty():
		push_error("Weapon Stack is empty, please populate with weapons")
	else:
		animation_player.animation_finished.connect(_on_animation_finished)
		for i in weapon_stack:
			initialize(i) #current starts on the first weapon in the stack
		current_weapon_slot = weapon_stack[0]
		if check_valid_weapon_slot():
			enter()
			update_weapon_stack.emit(weapon_stack)
		
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
		
	if range(KEY_1, KEY_4).has(event.keycode):
		var _slot_number = (event.keycode - KEY_1)
		if weapon_stack.size()-1>=_slot_number:
			exit(weapon_stack[_slot_number])
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("WeaponUp"):
		if check_valid_weapon_slot():
			var weapon_index = weapon_stack.find(current_weapon_slot)
			weapon_index = min(weapon_index+1,weapon_stack.size()-1)
			exit(weapon_stack[weapon_index])

	if event.is_action_pressed("WeaponDown"):
		if check_valid_weapon_slot():
			var weapon_index = weapon_stack.find(current_weapon_slot)
			weapon_index = max(weapon_index-1,0)
			exit(weapon_stack[weapon_index])
		
	if event.is_action_pressed("Shoot"):
		if check_valid_weapon_slot():
			shoot()
	
	if event.is_action_released("Shoot"):
		if check_valid_weapon_slot():
			shot_count_update()
	
	if event.is_action_pressed("Reload"):
		if check_valid_weapon_slot():
			reload()
		
	if event.is_action_pressed("Drop_Weapon"):
		if check_valid_weapon_slot():
			drop(current_weapon_slot)
		
	if event.is_action_pressed("Melee"):
		if check_valid_weapon_slot():
			melee()

func check_valid_weapon_slot()->bool:
	if current_weapon_slot:
		if current_weapon_slot.weapon:
			return true
		else:
			push_warning("No Weapon Resource active on the weapon controler.")
	else:
		push_warning("No Current Weapon slot active on the weapon controler.")
	return false

func initialize(_weapon_slot: WeaponSlot):
	if !_weapon_slot or !_weapon_slot.weapon:
		return
	if _weapon_slot.weapon.weapon_spray:
		spray_profiles[_weapon_slot.weapon.weapon_name] = _weapon_slot.weapon.weapon_spray.instantiate()
	
	# Initialize weapon stats modifier system
	if not _weapon_slot.has_meta("weapon_stats"):
		var stats_modifier = WeaponStatsModifier.new()
		stats_modifier.initialize_from_weapon(_weapon_slot.weapon)
		_weapon_slot.set_meta("weapon_stats", stats_modifier)
	
	connect_weapon_to_hud.emit(_weapon_slot.weapon)

func enter() -> void:
	# Set up current weapon stats
	weapon_stats = current_weapon_slot.get_meta("weapon_stats", null)
	if weapon_stats:
		# Update fire rate timer
		fire_rate_timer.wait_time = weapon_stats.get_fire_interval()
		
		# Connect to stats changes so HUD auto-updates
		if not weapon_stats.stats_changed.is_connected(_on_weapon_stats_changed):
			weapon_stats.stats_changed.connect(_on_weapon_stats_changed)
	
	animation_player.queue(current_weapon_slot.weapon.pick_up_animation)
	weapon_changed.emit(current_weapon_slot.weapon.weapon_name)
	update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
	weapon_stats_updated.emit(weapon_stats)

func exit(_next_weapon: WeaponSlot) -> void:
	if _next_weapon != current_weapon_slot:
		# Disconnect from old weapon stats
		if weapon_stats and weapon_stats.stats_changed.is_connected(_on_weapon_stats_changed):
			weapon_stats.stats_changed.disconnect(_on_weapon_stats_changed)
		
		if animation_player.get_current_animation() != current_weapon_slot.weapon.change_animation:
			animation_player.queue(current_weapon_slot.weapon.change_animation)
			next_weapon = _next_weapon

func change_weapon(weapon_slot: WeaponSlot) -> void:
	current_weapon_slot = weapon_slot
	next_weapon = null
	enter()
	
func shot_count_update() -> void:
	shot_tween = get_tree().create_tween()
	shot_tween.tween_property(self,"_count",0,1)
	
func shoot() -> void:
	# Check fire rate limit (performance optimized) - but skip for auto-fire weapons on manual trigger
	if not fire_rate_timer.is_stopped() and not current_weapon_slot.weapon.auto_fire:
		return  # Still in fire rate cooldown
	
	if current_weapon_slot.current_ammo != 0 or not current_weapon_slot.weapon.has_ammo:
		if current_weapon_slot.weapon.incremental_reload and animation_player.current_animation == current_weapon_slot.weapon.reload_animation:
			animation_player.stop()
			
		if not animation_player.is_playing():
			# Use weapon stats for modified values
			var anim_speed = weapon_stats.get_animation_speed() if weapon_stats else 1.0
			animation_player.play(current_weapon_slot.weapon.shoot_animation, -1, anim_speed)
			
			# Start fire rate cooldown
			if weapon_stats:
				var fire_interval = weapon_stats.get_fire_interval()
				fire_rate_timer.start(fire_interval)
			else:
				fire_rate_timer.start(2.0)  # Default fallback
			
			if current_weapon_slot.weapon.has_ammo:
				current_weapon_slot.current_ammo -= 1
				
			update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
			
			if shot_tween:
				shot_tween.kill()
			
			var Spread = Vector2.ZERO
			
			if current_weapon_slot.weapon.weapon_spray:
				_count = _count + 1
				Spread = spray_profiles[current_weapon_slot.weapon.weapon_name].Get_Spray(_count, current_weapon_slot.weapon.magazine)
				
			load_projectile(Spread)
	else:
		reload()

func auto_fire_shoot() -> void:
	# Auto-fire shooting - bypasses fire rate timer since animation controls timing
	if current_weapon_slot.current_ammo != 0 or not current_weapon_slot.weapon.has_ammo:
		if current_weapon_slot.weapon.incremental_reload and animation_player.current_animation == current_weapon_slot.weapon.reload_animation:
			animation_player.stop()
			
		# Use weapon stats for modified values
		var anim_speed = weapon_stats.get_animation_speed() if weapon_stats else 1.0
		animation_player.play(current_weapon_slot.weapon.shoot_animation, -1, anim_speed)
		
		if current_weapon_slot.weapon.has_ammo:
			current_weapon_slot.current_ammo -= 1
			
		update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
		
		if shot_tween:
			shot_tween.kill()
		
		var Spread = Vector2.ZERO
		
		if current_weapon_slot.weapon.weapon_spray:
			_count = _count + 1
			Spread = spray_profiles[current_weapon_slot.weapon.weapon_name].Get_Spray(_count, current_weapon_slot.weapon.magazine)
			
		load_projectile(Spread)
	else:
		reload()
		
func load_projectile(_spread):
	var _projectile:Projectile = current_weapon_slot.weapon.projectile_to_load.instantiate()
	
	_projectile.position = bullet_point.global_position
	_projectile.rotation = owner.rotation
	
	# Set projectile source for damage system
	_projectile.projectile_source = owner  # The player character
	_projectile.damage_type = DamageSystem.DamageType.BULLET
	
	bullet_point.add_child(_projectile)
	add_signal_to_hud.emit(_projectile)
	var bullet_point_origin = bullet_point.global_position
	
	# Use modified weapon stats
	var damage = weapon_stats.final_damage if weapon_stats else current_weapon_slot.weapon.damage
	var range = weapon_stats.final_fire_range if weapon_stats else current_weapon_slot.weapon.fire_range
	_projectile._Set_Projectile(damage, _spread, range, bullet_point_origin)

func reload() -> void:
	if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
		return
	elif not animation_player.is_playing():
		if current_weapon_slot.reserve_ammo != 0:
			animation_player.queue(current_weapon_slot.weapon.reload_animation)
		else:
			animation_player.queue(current_weapon_slot.weapon.out_of_ammo_animation)

func calculate_reload() -> void:
	if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
		var anim_legnth = animation_player.get_current_animation_length()
		animation_player.advance(anim_legnth)
		return
		
	var Mag_Amount = current_weapon_slot.weapon.magazine
	
	if current_weapon_slot.weapon.incremental_reload:
		Mag_Amount = current_weapon_slot.current_ammo+1
		
	var Reload_Amount = min(Mag_Amount-current_weapon_slot.current_ammo,Mag_Amount,current_weapon_slot.reserve_ammo)

	current_weapon_slot.current_ammo = current_weapon_slot.current_ammo+Reload_Amount
	current_weapon_slot.reserve_ammo = current_weapon_slot.reserve_ammo-Reload_Amount
	
	update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
	shot_count_update()

func melee() -> void:
	var Current_Anim = animation_player.get_current_animation()
	
	if Current_Anim == current_weapon_slot.weapon.shoot_animation:
		return
		
	if Current_Anim != current_weapon_slot.weapon.melee_animation:
		animation_player.play(current_weapon_slot.weapon.melee_animation)
		if melee_hitbox.is_colliding():
			var colliders = melee_hitbox.get_collision_count()
			for c in colliders:
				var Target = melee_hitbox.get_collider(c)
				if Target.is_in_group("Target"):
					hit_successfull.emit()
					var Direction = (Target.global_transform.origin - owner.global_transform.origin).normalized()
					var Position =  melee_hitbox.get_collision_point(c)
					# Use modified melee damage and damage system
					var melee_damage = weapon_stats.final_melee_damage if weapon_stats else current_weapon_slot.weapon.melee_damage
					DamageSystem.apply_damage_to_target(
						Target,
						melee_damage,
						owner,
						DamageSystem.DamageType.MELEE,
						Direction,
						Position,
						false
					)
			
func drop(_slot: WeaponSlot) -> void:
	if _slot.weapon.can_be_dropped and weapon_stack.size() != 1:
		var weapon_index = weapon_stack.find(_slot,0)
		if weapon_index != -1:
			weapon_stack.pop_at(weapon_index)
			update_weapon_stack.emit(weapon_stack)

			if _slot.weapon.weapon_drop:
				var weapon_dropped = _slot.weapon.weapon_drop.instantiate()
				weapon_dropped.weapon = _slot
				weapon_dropped.set_global_transform(bullet_point.get_global_transform())
				get_tree().get_root().add_child(weapon_dropped)
				
				animation_player.play(current_weapon_slot.weapon.drop_animation)
				weapon_index  = max(weapon_index-1,0)
				exit(weapon_stack[weapon_index])
	else:
		return
		
func _on_animation_finished(anim_name):
	if anim_name == current_weapon_slot.weapon.shoot_animation:
		# Auto-fire: if weapon supports auto-fire and shoot button is held, shoot again
		if current_weapon_slot.weapon.auto_fire and Input.is_action_pressed("Shoot"):
			auto_fire_shoot()  # Use auto-fire function

	if anim_name == current_weapon_slot.weapon.change_animation:
		change_weapon(next_weapon)
	
	if anim_name == current_weapon_slot.weapon.reload_animation:
		if !current_weapon_slot.weapon.incremental_reload:
			calculate_reload()

func _on_pick_up_detection_body_entered(body: RigidBody3D):
	var weapon_slot = body.weapon
	for slot in weapon_stack:
		if slot.weapon == weapon_slot.weapon:
			var remaining

			remaining = add_ammo(slot, weapon_slot.current_ammo+weapon_slot.reserve_ammo)
			weapon_slot.current_ammo = min(remaining, slot.weapon.magazine)
			weapon_slot.reserve_ammo = max(remaining - weapon_slot.current_ammo,0)

			if remaining == 0:
				body.queue_free()
			return
		
	if body.TYPE == "Weapon":
		if weapon_stack.size() == max_weapons:
				return
				
		if body.Pick_Up_Ready == true:
			var weapon_index = weapon_stack.find(current_weapon_slot)
			weapon_stack.insert(weapon_index,weapon_slot)
			update_weapon_stack.emit(weapon_stack)
			exit(weapon_slot)
			initialize(weapon_slot)
			body.queue_free()

func add_ammo(_weapon_slot: WeaponSlot, ammo: int)->int:
	var weapon = _weapon_slot.weapon
	# Use modified max ammo if stats are available
	var stats = _weapon_slot.get_meta("weapon_stats", null)
	var max_ammo = stats.final_max_ammo if stats else weapon.max_ammo
	
	var required = max_ammo - _weapon_slot.reserve_ammo
	var remaining = max(ammo - required,0)
	_weapon_slot.reserve_ammo += min(ammo, required)
	update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
	return remaining

## Get current weapon stats modifier (for external access)
func get_current_weapon_stats() -> WeaponStatsModifier:
	return weapon_stats

## Add temporary stat modifier to current weapon
func add_stat_modifier(stat_name: String, additive: float = 0.0, multiplicative: float = 1.0) -> void:
	if weapon_stats:
		weapon_stats.add_temporary_modifier(stat_name, additive, multiplicative)
		# Stats will auto-update via stats_changed signal
