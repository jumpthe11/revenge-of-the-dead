extends Node3D

class_name AIWeaponController

## Streamlined weapon controller for AI enemies
## Optimized for performance without complex state management

signal weapon_fired
signal target_hit
signal out_of_ammo

@export var weapon_resource: AIWeaponResource
@export var fire_point: Node3D ## Where projectiles spawn from

# Internal state
var can_fire: bool = true
var current_burst_count: int = 0
var is_bursting: bool = false
var active_projectiles: Array[Node] = []
var projectile_pool: Array[Node] = []

# Timers
var fire_timer: Timer
var burst_timer: Timer

func _ready() -> void:
	if not weapon_resource:
		push_error("AI Weapon Controller '%s' is missing weapon resource!" % get_parent().name)
		return
	
	print("AI Weapon Controller loaded: %s with resource: %s" % [get_parent().name, weapon_resource.weapon_name])
	
	_setup_timers()
	_setup_projectile_pool()

func _setup_timers() -> void:
	# Fire rate timer
	fire_timer = Timer.new()
	fire_timer.wait_time = weapon_resource.fire_rate
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)
	
	# Burst cooldown timer
	if weapon_resource.burst_fire:
		burst_timer = Timer.new()
		burst_timer.wait_time = weapon_resource.burst_cooldown
		burst_timer.one_shot = true
		burst_timer.timeout.connect(_on_burst_timer_timeout)
		add_child(burst_timer)

func _setup_projectile_pool() -> void:
	if not weapon_resource.use_projectile_pooling or not weapon_resource.projectile_scene:
		return
	
	# Pre-instantiate projectiles for pooling
	for i in weapon_resource.max_active_projectiles:
		var projectile = weapon_resource.projectile_scene.instantiate()
		projectile_pool.append(projectile)
		# Don't add to scene tree yet

## Attempt to fire weapon at target position
func fire_at_target(target_position: Vector3) -> bool:
	if not can_fire or not weapon_resource:
		return false
	
	# Check if we're in a burst and haven't exceeded burst count
	if weapon_resource.burst_fire and is_bursting:
		if current_burst_count >= weapon_resource.burst_count:
			return false
	
	# Check active projectile limit
	if active_projectiles.size() >= weapon_resource.max_active_projectiles:
		return false
	
	_fire_projectile(target_position)
	
	# Handle burst firing
	if weapon_resource.burst_fire:
		is_bursting = true
		current_burst_count += 1
		
		if current_burst_count >= weapon_resource.burst_count:
			_start_burst_cooldown()
	else:
		_start_fire_cooldown()
	
	weapon_fired.emit()
	return true

func _fire_projectile(target_position: Vector3) -> void:
	var projectile = _get_projectile()
	if not projectile:
		return
	
	var spawn_position = fire_point.global_position if fire_point else global_position
	
	# Apply accuracy spread
	var direction = (target_position - spawn_position).normalized()
	direction = _apply_spread(direction)
	
	# Setup projectile based on type
	match weapon_resource.projectile_type:
		"Hitscan":
			_fire_hitscan_projectile(projectile, spawn_position, direction)
		"Physics":
			_fire_physics_projectile(projectile, spawn_position, direction)

func _get_projectile() -> Node:
	var projectile: Node
	
	if weapon_resource.use_projectile_pooling and not projectile_pool.is_empty():
		projectile = projectile_pool.pop_back()
	elif weapon_resource.projectile_scene:
		projectile = weapon_resource.projectile_scene.instantiate()
	
	if projectile:
		active_projectiles.append(projectile)
		get_tree().current_scene.add_child(projectile)
		
		# Connect cleanup signal if projectile supports it
		if projectile.has_signal("projectile_destroyed"):
			projectile.projectile_destroyed.connect(_on_projectile_destroyed.bind(projectile))
	
	return projectile

func _fire_hitscan_projectile(projectile: Node, spawn_position: Vector3, direction: Vector3) -> void:
	projectile.global_position = spawn_position
	
	# If it's our custom projectile, use simplified setup
	if projectile.has_method("_Set_Projectile"):
		# Set projectile source to AI enemy (parent)
		if projectile.has("projectile_source"):
			projectile.projectile_source = get_parent()  # The AI enemy
		if projectile.has("damage_type"):
			projectile.damage_type = DamageSystem.DamageType.BULLET
		
		var damage = weapon_resource.damage
		var range_limit = weapon_resource.max_range
		projectile._Set_Projectile(damage, Vector2.ZERO, range_limit, spawn_position)

func _fire_physics_projectile(projectile: Node, spawn_position: Vector3, direction: Vector3) -> void:
	projectile.global_position = spawn_position
	
	# Set projectile source to AI enemy (parent)
	if projectile.has("projectile_source"):
		projectile.projectile_source = get_parent()  # The AI enemy
	if projectile.has("damage_type"):
		projectile.damage_type = DamageSystem.DamageType.BULLET
	
	# Set velocity for RigidBody projectiles
	if projectile is RigidBody3D:
		projectile.linear_velocity = direction * weapon_resource.projectile_speed
		projectile.look_at(spawn_position + direction)

func _apply_spread(direction: Vector3) -> Vector3:
	if weapon_resource.accuracy_spread <= 0.0:
		return direction
	
	# Convert spread from degrees to radians
	var spread_rad = deg_to_rad(weapon_resource.accuracy_spread)
	
	# Apply random spread
	var random_spread = Vector3(
		randf_range(-spread_rad, spread_rad),
		randf_range(-spread_rad, spread_rad),
		0.0
	)
	
	# Rotate direction by spread
	var basis = Basis.looking_at(direction)
	return basis * Vector3.FORWARD + random_spread

func _start_fire_cooldown() -> void:
	can_fire = false
	fire_timer.start()

func _start_burst_cooldown() -> void:
	can_fire = false
	is_bursting = false
	current_burst_count = 0
	if burst_timer:
		burst_timer.start()

func _on_fire_timer_timeout() -> void:
	if not weapon_resource.burst_fire or not is_bursting:
		can_fire = true

func _on_burst_timer_timeout() -> void:
	can_fire = true

func _on_projectile_destroyed(projectile: Node) -> void:
	active_projectiles.erase(projectile)
	
	# Return to pool if using pooling
	if weapon_resource.use_projectile_pooling:
		projectile_pool.append(projectile)
		projectile.get_parent().remove_child(projectile)
	else:
		projectile.queue_free()

## Check if weapon can engage target at given distance
func can_engage_target(distance: float) -> bool:
	if not weapon_resource:
		return false
	return weapon_resource.is_in_range(distance)

## Get the effective damage at given distance
func get_damage_at_distance(distance: float) -> int:
	if not weapon_resource:
		return 0
	return weapon_resource.calculate_damage_at_distance(distance)

## Force cleanup of all active projectiles (for performance)
func cleanup_projectiles() -> void:
	for projectile in active_projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	active_projectiles.clear()

func _exit_tree() -> void:
	cleanup_projectiles()
