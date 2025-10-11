extends CharacterBody3D

class_name AIEnemyBase

## Base AI enemy class with core functionality
## All specific AI types should extend from this class

signal enemy_died
signal enemy_damaged
signal target_acquired
signal target_lost

@export_group("AI Settings")
## Maximum health
@export var max_health: float = 100.0
## Movement speed
@export var move_speed: float = 5.0
## Rotation speed in radians per second
@export var rotation_speed: float = 3.0
## Detection range for finding targets
@export var detection_range: float = 30.0
## Time to lose target after losing line of sight
@export var target_loss_time: float = 3.0

@export_group("Components")
## Weapon controller for this AI
@export var weapon_controller: AIWeaponController
## Area3D for detection (if not using raycast)
@export var detection_area: Area3D

# Internal state
var current_health: float
var current_target: Node3D = null
var target_last_position: Vector3 = Vector3.ZERO
var target_loss_timer: Timer

# AI State
enum AIState { IDLE, PATROLLING, CHASING, ATTACKING, DEAD }
var current_state: AIState = AIState.IDLE

# Performance optimization
var update_counter: int = 0
var raycast_query: PhysicsRayQueryParameters3D
var space_state: PhysicsDirectSpaceState3D

func _ready() -> void:
	current_health = max_health
	space_state = get_world_3d().direct_space_state
	_update_health_display()
	_setup_timers()
	_setup_weapon_controller()
	_setup_detection()
	
	# Add to Target group so player weapons can hit us
	add_to_group("Target")

func _setup_timers() -> void:
	target_loss_timer = Timer.new()
	target_loss_timer.wait_time = target_loss_time
	target_loss_timer.one_shot = true
	target_loss_timer.timeout.connect(_on_target_lost)
	add_child(target_loss_timer)

func _setup_weapon_controller() -> void:
	if weapon_controller:
		weapon_controller.target_hit.connect(_on_weapon_hit_target)

func _setup_detection() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta: float) -> void:
	if current_state == AIState.DEAD:
		return
	
	# Performance: Update different systems on different frames
	update_counter += 1
	if update_counter % 3 == 0:
		_update_target_detection()
	
	_update_ai_state(delta)
	_apply_movement(delta)

func _update_target_detection() -> void:
	# Only check for targets if we don't have one or need to verify line of sight
	if not current_target:
		_find_target()
	else:
		_verify_target()

func _find_target() -> void:
	# Simple detection: find player within range
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	if distance <= detection_range:
		if _has_line_of_sight_to(player.global_position):
			_acquire_target(player)

func _verify_target() -> void:
	if not is_instance_valid(current_target):
		_lose_target()
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	if distance > detection_range * 1.5: # Give some buffer
		_lose_target()
		return
	
	if weapon_controller and weapon_controller.weapon_resource.requires_line_of_sight:
		if not _has_line_of_sight_to(current_target.global_position):
			target_loss_timer.start()
			return
	
	# Target is valid, update last known position
	target_last_position = current_target.global_position
	if target_loss_timer.time_left > 0:
		target_loss_timer.stop()

func _has_line_of_sight_to(target_pos: Vector3) -> bool:
	raycast_query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, target_pos + Vector3.UP)
	raycast_query.collision_mask = 0b11111101 # Exclude player layer
	
	var result = space_state.intersect_ray(raycast_query)
	return result.is_empty()

func _acquire_target(target: Node3D) -> void:
	current_target = target
	target_last_position = target.global_position
	target_acquired.emit()

func _lose_target() -> void:
	current_target = null
	target_lost.emit()

func _on_target_lost() -> void:
	_lose_target()

func _update_ai_state(delta: float) -> void:
	match current_state:
		AIState.IDLE:
			if current_target:
				current_state = AIState.CHASING
		
		AIState.CHASING:
			if not current_target:
				current_state = AIState.IDLE
			else:
				var distance = global_position.distance_to(current_target.global_position)
				if weapon_controller and weapon_controller.can_engage_target(distance):
					current_state = AIState.ATTACKING
		
		AIState.ATTACKING:
			if not current_target:
				current_state = AIState.IDLE
			else:
				var distance = global_position.distance_to(current_target.global_position)
				if weapon_controller and not weapon_controller.can_engage_target(distance):
					current_state = AIState.CHASING

func _apply_movement(delta: float) -> void:
	match current_state:
		AIState.CHASING:
			_move_towards_target(delta)
		
		AIState.ATTACKING:
			_combat_movement(delta)

func _move_towards_target(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var direction = (target_position - global_position).normalized()
	
	# Move towards target
	velocity = direction * move_speed
	
	# Rotate towards target
	_rotate_towards(target_position, delta)
	
	move_and_slide()

func _combat_movement(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var distance = global_position.distance_to(target_position)
	
	# Stop moving if at optimal range, otherwise adjust
	if weapon_controller:
		var optimal_range = weapon_controller.weapon_resource.get_optimal_range()
		
		if distance > optimal_range:
			# Move closer
			var direction = (target_position - global_position).normalized()
			velocity = direction * move_speed * 0.5 # Slower in combat
		elif distance < weapon_controller.weapon_resource.min_range:
			# Move away
			var direction = (global_position - target_position).normalized()
			velocity = direction * move_speed * 0.3
		else:
			# At good range, just rotate
			velocity = Vector3.ZERO
	
	# Always face target in combat
	_rotate_towards(target_position, delta)
	
	# Try to fire weapon
	if weapon_controller:
		weapon_controller.fire_at_target(target_position)
	
	move_and_slide()

func _rotate_towards(target_position: Vector3, delta: float) -> void:
	var direction = (target_position - global_position).normalized()
	var target_rotation = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

## Hit_Successful method - required for compatibility with existing weapon system
func Hit_Successful(damage: float, _Direction: Vector3 = Vector3.ZERO, _Position: Vector3 = Vector3.ZERO) -> void:
	take_damage(damage)
	
	# Apply knockback if direction is provided
	if _Direction != Vector3.ZERO and is_on_floor():
		# Simple knockback - can be enhanced per AI type
		var knockback_force = _Direction * damage * 0.1
		velocity += Vector3(knockback_force.x, 0, knockback_force.z)

## Take damage from external sources
func take_damage(damage: float, source: Node = null) -> void:
	if current_state == AIState.DEAD:
		return
	
	current_health -= damage
	_update_health_display()
	enemy_damaged.emit()
	
	if current_health <= 0:
		_die()

## Update health bar display
func _update_health_display() -> void:
	var health_bar = get_node_or_null("HealthCounter")
	if health_bar:
		health_bar.text = str(current_health)
	#var health_bar = get_node_or_null("HealthBar")
	#if health_bar:
	#	health_bar.value = current_health

func _die() -> void:
	current_state = AIState.DEAD
	enemy_died.emit()
	
	# Clean up weapon controller
	if weapon_controller:
		weapon_controller.cleanup_projectiles()
	
	# Can override this in derived classes for death effects
	_on_death()

## Override this in derived classes for custom death behavior
func _on_death() -> void:
	queue_free()

func _on_weapon_hit_target() -> void:
	# Called when our weapon hits something
	pass

func _on_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		_acquire_target(body)

func _on_detection_body_exited(body: Node3D) -> void:
	if body == current_target:
		target_loss_timer.start()

## Get current health percentage (0.0 to 1.0)
func get_health_percentage() -> float:
	return current_health / max_health

## Check if AI is alive
func is_alive() -> bool:
	return current_state != AIState.DEAD
