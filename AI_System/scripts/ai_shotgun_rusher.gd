extends AIEnemyBase

class_name AIShotgunRusher

## Shotgun-specialized AI that rushes in for close-range combat
## Aggressive and fast, tries to get close quickly

@export_group("Shotgun Behavior")
## Maximum rush distance to engage
@export var rush_distance: float = 15.0
## Speed boost when rushing
@export var rush_speed_multiplier: float = 1.5
## Time between shots for double-tap
@export var double_tap_delay: float = 0.2

# Shotgun-specific state
var is_rushing: bool = false
var double_tap_timer: Timer
var shots_fired: int = 0

func _ready() -> void:
	super._ready()
	_setup_shotgun_behavior()
	

func _setup_shotgun_behavior() -> void:
	# Set up double-tap timer
	double_tap_timer = Timer.new()
	double_tap_timer.wait_time = double_tap_delay
	double_tap_timer.one_shot = true
	double_tap_timer.timeout.connect(_on_double_tap_ready)
	add_child(double_tap_timer)
	
	# Shotgun rushers are more aggressive
	detection_range = detection_range * 1.2

func _combat_movement(delta: float) -> void:
	if not current_target or not weapon_controller or not weapon_controller.weapon_resource:
		return
	
	var target_position = current_target.global_position
	var distance = global_position.distance_to(target_position)
	
	# Always rush towards target if not in optimal range
	if distance > weapon_controller.weapon_resource.get_optimal_range():
		is_rushing = true
		_rush_towards_target(delta)
	else:
		is_rushing = false
		# At close range, circle strafe aggressively
		_aggressive_strafe(delta)
	
	# Face target
	_rotate_towards(target_position, delta)
	
	# Handle shotgun combat
	_handle_shotgun_combat()
	
	move_and_slide()

func _rush_towards_target(delta: float) -> void:
	var target_position = current_target.global_position
	var direction = (target_position - global_position).normalized()
	
	# Rush at high speed
	var rush_speed = move_speed * rush_speed_multiplier
	velocity.x = direction.x * rush_speed
	velocity.z = direction.z * rush_speed

func _aggressive_strafe(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var to_target = (target_position - global_position).normalized()
	
	# Create perpendicular strafe direction
	var strafe_direction = Vector3(-to_target.z, 0, to_target.x)
	
	# Alternate strafe direction
	if sin(Time.get_ticks_msec() * 0.002) > 0:
		strafe_direction = -strafe_direction
	
	velocity.x = strafe_direction.x * move_speed * 0.8
	velocity.z = strafe_direction.z * move_speed * 0.8

func _handle_shotgun_combat() -> void:
	if not current_target or not weapon_controller:
		return
	
	var target_position = current_target.global_position
	var distance = global_position.distance_to(target_position)
	
	if not weapon_controller.can_engage_target(distance):
		return
	
	# Check if we have line of sight
	if not _has_line_of_sight_to(target_position):
		return
	
	# Shotgun double-tap logic
	if weapon_controller.fire_at_target(target_position):
		shots_fired += 1
		
		# Trigger double-tap if it's the first shot
		if shots_fired == 1:
			double_tap_timer.start()

func _on_double_tap_ready() -> void:
	# Ready for second shot
	if current_target and weapon_controller:
		if weapon_controller.fire_at_target(current_target.global_position):
			shots_fired = 0  # Reset counter after double-tap

func _update_ai_state(delta: float) -> void:
	# Override parent for more aggressive behavior
	match current_state:
		AIState.IDLE:
			if current_target:
				current_state = AIState.CHASING
		
		AIState.CHASING:
			if not current_target:
				current_state = AIState.IDLE
			else:
				var distance = global_position.distance_to(current_target.global_position)
				# Shotgun rushers engage from farther away but rush in
				if distance <= rush_distance:
					current_state = AIState.ATTACKING
		
		AIState.ATTACKING:
			if not current_target:
				current_state = AIState.IDLE
			else:
				var distance = global_position.distance_to(current_target.global_position)
				# Only fall back if target gets very far away
				if distance > rush_distance * 2.0:
					current_state = AIState.CHASING

func _move_towards_target(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var distance = global_position.distance_to(target_position)
	
	# If within rush distance, switch to attacking immediately
	if distance <= rush_distance:
		current_state = AIState.ATTACKING
		return
	
	# Otherwise move normally but faster than base class
	var direction = (target_position - global_position).normalized()
	velocity.x = direction.x * move_speed * 1.2  # Faster approach
	velocity.z = direction.z * move_speed * 1.2
	
	_rotate_towards(target_position, delta)
	move_and_slide()

func take_damage(damage: float, source: Node = null) -> void:
	super.take_damage(damage, source)
	
	# When damaged, become more aggressive
	if is_alive() and source:
		if not current_target:
			_acquire_target(source)
		
		# If already rushing, increase speed temporarily
		if is_rushing:
			rush_speed_multiplier = min(rush_speed_multiplier * 1.1, 2.5)

func _on_death() -> void:
	# Shotgun rushers might explode or something dramatic
	_dramatic_death()
	super._on_death()

func _dramatic_death() -> void:
	# Could add explosion effect or dramatic death animation
	pass
