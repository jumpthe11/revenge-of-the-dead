extends AIEnemyBase

class_name AIMeleeBrute

## Melee-specialized AI that charges at targets for close combat
## High health, high damage, but slow and vulnerable at range

@export_group("Melee Behavior")
## Distance at which to start charging
@export var charge_distance: float = 20.0
## Speed multiplier during charge
@export var charge_speed_multiplier: float = 2.0
## Charge cooldown time
@export var charge_cooldown: float = 3.0
## Damage dealt on melee attack
@export var melee_damage: float = 50.0
## Melee attack range
@export var melee_range: float = 3.0


# Melee-specific state
var is_charging: bool = false
var can_charge: bool = true
var charge_timer: Timer
var melee_attack_timer: Timer

func _ready() -> void:
	# Melee brutes are tankier but slower
	max_health *= 50
	move_speed *= 0.8  # Slower base speed
	
	super._ready()
	_setup_melee_behavior()


func _setup_melee_behavior() -> void:
	# Set up charge cooldown timer
	charge_timer = Timer.new()
	charge_timer.wait_time = charge_cooldown
	charge_timer.one_shot = true
	charge_timer.timeout.connect(_on_charge_ready)
	add_child(charge_timer)
	
	# Set up melee attack timer
	melee_attack_timer = Timer.new()
	melee_attack_timer.wait_time = 0.5  # Attack cooldown
	melee_attack_timer.one_shot = true
	add_child(melee_attack_timer)
	
	# Melee brutes have longer detection range to compensate for being slow
	detection_range = detection_range * 1.3



func _combat_movement(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var distance = global_position.distance_to(target_position)
	
	# Check if we should charge
	if distance <= charge_distance and can_charge and not is_charging:
		_start_charge()
	
	if is_charging:
		_charge_movement(delta)
	elif distance > melee_range:
		_move_towards_target_aggressively(delta)
	else:
		# At melee range, try to attack
		_melee_attack()
		velocity.x = 0
		velocity.z = 0
	
	# Face target
	_rotate_towards(target_position, delta)
	move_and_slide()

func _start_charge() -> void:
	if not can_charge:
		return
	
	is_charging = true
	can_charge = false
	charge_timer.start()
	
	# Charge lasts for a short duration
	get_tree().create_timer(1.5).timeout.connect(_end_charge)

func _end_charge() -> void:
	is_charging = false

func _on_charge_ready() -> void:
	can_charge = true

func _charge_movement(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var direction = (target_position - global_position).normalized()
	
	# Charge at high speed
	var charge_speed = move_speed * charge_speed_multiplier
	velocity.x = direction.x * charge_speed
	velocity.z = direction.z * charge_speed

func _move_towards_target_aggressively(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var direction = (target_position - global_position).normalized()
	
	# Move faster when not charging but still aggressively
	velocity.x = direction.x * move_speed * 1.2
	velocity.z = direction.z * move_speed * 1.2

func _melee_attack() -> void:
	if melee_attack_timer.time_left > 0:
		return
	
	if not current_target:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	if distance <= melee_range:
		# Deal damage to target using DamageSystem
		if current_target.is_in_group("Target"):
			var direction = (current_target.global_position - global_position).normalized()
			DamageSystem.apply_damage_to_target(
				current_target,
				melee_damage,
				self,
				DamageSystem.DamageType.MELEE,
				direction,
				current_target.global_position,
				false
			)
		
		melee_attack_timer.start()
		
		# Add knockback effect
		if current_target.has_method("apply_knockback"):
			var knockback_direction = (current_target.global_position - global_position).normalized()
			current_target.apply_knockback(knockback_direction * 10.0)

func _update_ai_state(delta: float) -> void:
	# Override parent for melee-specific behavior
	match current_state:
		AIState.IDLE:
			if current_target:
				current_state = AIState.CHASING
		
		AIState.CHASING:
			if not current_target:
				current_state = AIState.IDLE
			else:
				var distance = global_position.distance_to(current_target.global_position)
				# Always attacking if within charge distance
				if distance <= charge_distance:
					current_state = AIState.ATTACKING
		
		AIState.ATTACKING:
			if not current_target:
				current_state = AIState.IDLE
			else:
				var distance = global_position.distance_to(current_target.global_position)
				# Only fall back if target gets really far away
				if distance > charge_distance * 1.8:
					current_state = AIState.CHASING

func _move_towards_target(delta: float) -> void:
	if not current_target:
		return
	
	var target_position = current_target.global_position
	var distance = global_position.distance_to(target_position)
	
	# If within charge distance, switch to attacking
	if distance <= charge_distance:
		current_state = AIState.ATTACKING
		return
	
	# Move aggressively towards target
	_move_towards_target_aggressively(delta)
	_rotate_towards(target_position, delta)
	move_and_slide()

func take_damage(damage: float, source: Node = null) -> void:
	super.take_damage(damage, source)
	
	# When damaged, become enraged and potentially charge
	if is_alive() and source:
		if not current_target:
			_acquire_target(source)
		
		# Reduce charge cooldown when damaged
		if charge_timer.time_left > 1.0:
			charge_timer.wait_time = max(charge_timer.time_left - 1.0, 0.5)

func _on_death() -> void:
	# Melee brutes might have area damage on death
	_death_explosion()
	super._on_death()

func _death_explosion() -> void:
	# Deal area damage around the brute when it dies
	var explosion_range = 5.0
	var explosion_damage = 20.0
	
	space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = explosion_range
	query.shape = sphere
	query.transform.origin = global_position
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result["collider"]
		if body != self and body.is_in_group("Target"):
			var direction = (body.global_position - global_position).normalized()
			DamageSystem.apply_damage_to_target(
				body,
				explosion_damage,
				self,
				DamageSystem.DamageType.EXPLOSIVE,
				direction,
				body.global_position,
				false
			)
