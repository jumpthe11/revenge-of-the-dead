extends AIEnemyBase

class_name AIRifleSoldier

## Rifle-specialized AI that prefers medium-range combat
## Uses cover and maintains optimal distance

@export_group("Rifle Behavior")
## Preferred engagement distance
@export var preferred_distance: float = 25.0
## Time to aim before firing
@export var aim_time: float = 0.3
## Whether to use suppressive fire
@export var use_suppressive_fire: bool = true
## Suppressive fire duration
@export var suppressive_fire_duration: float = 2.0

# Rifle-specific state
var is_aiming: bool = false
var aim_timer: Timer
var suppressive_timer: Timer
var last_known_target_position: Vector3

func _ready() -> void:
	super._ready()
	_setup_rifle_behavior()

func _setup_rifle_behavior() -> void:
	# Set up aim timer
	aim_timer = Timer.new()
	aim_timer.wait_time = aim_time
	aim_timer.one_shot = true
	aim_timer.timeout.connect(_on_aim_complete)
	add_child(aim_timer)
	
	# Set up suppressive fire timer
	if use_suppressive_fire:
		suppressive_timer = Timer.new()
		suppressive_timer.wait_time = suppressive_fire_duration
		suppressive_timer.one_shot = true
		suppressive_timer.timeout.connect(_on_suppressive_fire_complete)
		add_child(suppressive_timer)

func _combat_movement(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var distance = global_position.distance_to(target_position)
	
	# Rifle soldiers prefer to maintain preferred distance
	if abs(distance - preferred_distance) > 3.0:
		var direction: Vector3
		if distance > preferred_distance:
			# Too far, move closer
			direction = (target_position - global_position).normalized()
			velocity.x = direction.x * move_speed * 0.6
			velocity.z = direction.z * move_speed * 0.6
		else:
			# Too close, back away
			direction = (global_position - target_position).normalized()
			velocity.x = direction.x * move_speed * 0.4
			velocity.z = direction.z * move_speed * 0.4
	else:
		# At good distance, use strafing movement
		_strafe_movement(delta)
	
	# Face target
	_rotate_towards(target_position, delta)
	
	# Handle firing logic
	_handle_rifle_combat()
	
	move_and_slide()

func _strafe_movement(delta: float) -> void:
	# Simple strafing to make AI harder to hit
	var strafe_direction = Vector3(sin(Time.get_ticks_msec() * 0.001), 0, 0)
	velocity.x = strafe_direction.x * move_speed * 0.3
	velocity.z = strafe_direction.z * move_speed * 0.3

func _handle_rifle_combat() -> void:
	if not current_target or not weapon_controller:
		return
	
	var target_position = current_target.global_position
	var distance = global_position.distance_to(target_position)
	
	if not weapon_controller.can_engage_target(distance):
		return
	
	# Check if we have line of sight
	if not _has_line_of_sight_to(target_position):
		if use_suppressive_fire and not suppressive_timer.time_left > 0:
			_start_suppressive_fire()
		return
	
	# If we can see target, aim and fire
	if not is_aiming and aim_timer.is_stopped():
		_start_aiming()
	elif is_aiming:
		# Try to fire while aiming
		weapon_controller.fire_at_target(target_position)

func _start_aiming() -> void:
	is_aiming = true
	aim_timer.start()

func _on_aim_complete() -> void:
	is_aiming = false

func _start_suppressive_fire() -> void:
	if not suppressive_timer:
		return
	
	last_known_target_position = target_last_position
	suppressive_timer.start()

func _on_suppressive_fire_complete() -> void:
	# Suppressive fire is complete
	pass

func _update_ai_state(delta: float) -> void:
	# Override parent to add rifle-specific states
	match current_state:
		AIState.IDLE:
			if current_target:
				current_state = AIState.CHASING
		
		AIState.CHASING:
			if not current_target:
				current_state = AIState.IDLE
			else:
				var distance = global_position.distance_to(current_target.global_position)
				# Rifles prefer to engage from medium distance
				if distance <= preferred_distance * 1.2:
					current_state = AIState.ATTACKING
		
		AIState.ATTACKING:
			if not current_target:
				current_state = AIState.IDLE
			else:
				var distance = global_position.distance_to(current_target.global_position)
				# Fall back to chasing if too far
				if distance > preferred_distance * 1.5:
					current_state = AIState.CHASING

func _on_death() -> void:
	# Rifle soldiers might drop their weapon
	_drop_weapon()
	super._on_death()

func _drop_weapon() -> void:
	# Could spawn a weapon pickup here
	pass
