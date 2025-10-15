extends CharacterBody3D

@onready var camera = %Camera
@export var subviewport_camera: Camera3D
@export var main_camera:Camera3D
@export var animation_tree: AnimationTree

# Health System
signal player_died
signal player_damaged(current_health: float, max_health: float)

@export_category("Health Parameters")
@export var max_health: float = 100.0
@export var health_regeneration: bool = false
@export var health_regen_rate: float = 5.0  # Health per second
@export var health_regen_delay: float = 5.0  # Seconds before regen starts after damage

var current_health: float
var health_regen_timer: float = 0.0
var is_dead: bool = false

var camera_rotation: Vector2 = Vector2(0.0,0.0)
var mouse_sensitivity = 0.001
var crouched: bool = false
var crouch_blocked: bool = false

@export_category("Crouch Parametres")
@export var enable_crouch: bool = true
@export var crouch_toggle: bool = false
@export var crouch_collision: ShapeCast3D
@export_range(0.0,3.0) var crouch_speed_reduction = 2.0
@export_range(0.0,0.50) var crouch_blend_speed = .2
enum {GROUND_CROUCH = -1, STANDING = 0, AIR_CROUCH = 1}

@export_category("Lean Parametres")
@export var enable_lean: bool = true
@export_range(0.0,1.0) var lean_speed: float = .2
@export var right_lean_collision: ShapeCast3D
@export var left_lean_collision: ShapeCast3D
var lean_tween
enum {LEFT = 1, CENTRE = 0, RIGHT = -1}

@export_category("speed Parameters")
@export var enable_sprint: bool = true
@export var sprint_timer: Timer
@export var sprint_cooldown_time: float = 0.77
@export var sprint_time: float = 5.0
@export var sprint_replenish_rate: float = 0.30
@export var acceleration: float = 120
@export_range(0.01,1.0) var air_acceleration_modifier: float = 0.1
var sprint_on_cooldown: bool = false
var sprint_time_remaining: float = sprint_time
@onready var sprint_bar: Range = $CanvasLayer/SprintBar

const NORMAL_speed = 1
@export_range(1.0,3.0) var sprint_speed: float = 2.0
@export_range(0.1,1.0) var walk_speed: float = 0.5
var speed_modifier: float = NORMAL_speed

@export_category("Jump Parameters")
@export var coyote_timer: Timer
@export var jump_peak_time: float = .5
@export var jump_fall_time: float = .5
@export var jump_height: float = 2.0
@export var jump_distance: float = 4.0
@export var coyote_time: float = .1
@export var jump_buffer_time: float = .2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var jump_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var fall_gravity: float
var jump_velocity: float
var base_speed: float 
var _speed: float 
var jump_available: bool = true
var jump_buffer: bool = false

func _ready() -> void:
	update_camera_rotation()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	calculate_movement_parameters()
	add_to_group("Player")
	add_to_group("Target")  # Required for projectiles and enemy weapons to hit player
	
	# Initialize health system
	current_health = max_health
	_update_health_display()
	
func update_camera_rotation() -> void:
	var current_rotation = get_rotation()
	camera_rotation.x = current_rotation.y
	camera_rotation.y = current_rotation.x
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * mouse_sensitivity
		camera_look(MouseEvent)
	
	if enable_crouch:
		if event.is_action_pressed("crouch"):
			crouch()
		if event.is_action_released("crouch"):
			if !crouch_toggle and crouched:
				crouch()
	
	if enable_lean:
		if Input.is_action_just_released("lean_left") or Input.is_action_just_released("lean_right"):
			if !(Input.is_action_pressed("lean_right") or Input.is_action_pressed("lean_left")):
				lean(CENTRE)
		if Input.is_action_just_pressed("lean_left"):
			lean(LEFT)
		if Input.is_action_just_pressed("lean_right"):
			lean(RIGHT)
		
	if enable_sprint:
		if Input.is_action_just_released("sprint") or Input.is_action_just_released("walk"):
			if !(Input.is_action_pressed("walk") or Input.is_action_pressed("sprint")):
				speed_modifier = NORMAL_speed
				exit_sprint()

		if Input.is_action_just_pressed("sprint") and !crouched:
			if !sprint_on_cooldown:
				speed_modifier = sprint_speed
				sprint_timer.start(sprint_time_remaining)

		if Input.is_action_just_pressed("walk") and !crouched:
			speed_modifier = walk_speed

func calculate_movement_parameters() -> void:
	jump_gravity = (2*jump_height)/pow(jump_peak_time,2)
	fall_gravity = (2*jump_height)/pow(jump_fall_time,2)
	jump_velocity = jump_gravity * jump_peak_time
	base_speed = jump_distance/(jump_peak_time+jump_fall_time)
	_speed = base_speed

func lean(blend_amount: int) -> void:
	if is_on_floor():
		if lean_tween:
			lean_tween.kill()
		
		lean_tween = get_tree().create_tween()
		lean_tween.tween_property(animation_tree,"parameters/lean_blend/blend_amount", blend_amount, lean_speed)

func lean_collision() -> void:
	animation_tree["parameters/left_collision_blend/blend_amount"] = lerp(
		float(animation_tree["parameters/left_collision_blend/blend_amount"]),float(left_lean_collision.is_colliding()),lean_speed
	)
	animation_tree["parameters/right_collision_blend/blend_amount"] = lerp(
		float(animation_tree["parameters/right_collision_blend/blend_amount"]),float(right_lean_collision.is_colliding()),lean_speed
	)

func crouch() -> void:
	var Blend
	if !crouch_collision.is_colliding():
		if crouched:
			Blend = STANDING
		else:
			speed_modifier = NORMAL_speed
			exit_sprint()
			
			if is_on_floor():
				Blend = GROUND_CROUCH
			else:
				Blend = AIR_CROUCH
		var blend_tween = get_tree().create_tween()
		blend_tween.tween_property(animation_tree,"parameters/Crouch_Blend/blend_amount",Blend,crouch_blend_speed)
		crouched = !crouched
	else:
		crouch_blocked = true

func camera_look(Movement: Vector2) -> void:
	camera_rotation += Movement
	
	transform.basis = Basis()
	camera.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0),-camera_rotation.x) # first rotate in Y
	camera.rotate_object_local(Vector3(1,0,0), -camera_rotation.y) # then rotate in X
	camera_rotation.y = clamp(camera_rotation.y,-1.5,1.2)
	
func exit_sprint() -> void:
	if !sprint_timer.is_stopped():
		sprint_time_remaining = sprint_timer.time_left
		sprint_timer.stop()

func sprint_replenish(delta) -> void:
	var sprint_bar_Value

	if !sprint_on_cooldown and (speed_modifier != sprint_speed):
		
		if is_on_floor():
			sprint_time_remaining = move_toward(sprint_time_remaining, sprint_time, delta*sprint_replenish_rate)
			
		sprint_bar_Value= (sprint_time_remaining/sprint_time)*100
		
	else:
		sprint_bar_Value = (sprint_timer.time_left/sprint_time)*100
	
	#sprint_bar_Value = ((int(Sprint)*sprint_time_remaining)+(int(!Sprint)*sprint_timer.time_left)/sprint_time)*100
	sprint_bar.value = sprint_bar_Value
	
	if sprint_bar_Value == 100:
		sprint_bar.hide()
	else:
		sprint_bar.show()

func _process(_delta: float) -> void:
	if subviewport_camera:
		subviewport_camera.global_transform = main_camera.global_transform
		
func _physics_process(_delta: float) -> void:
	if is_dead:
		return
		
	# Health regeneration
	if health_regeneration and current_health < max_health:
		health_regen_timer += _delta
		if health_regen_timer >= health_regen_delay:
			current_health = min(current_health + health_regen_rate * _delta, max_health)
			_update_health_display()
	
	sprint_replenish(_delta)
	lean_collision()
	
	if crouched and crouch_blocked:
		if !crouch_collision.is_colliding():
			crouch_blocked = false
			if !Input.is_action_pressed("crouch") and !crouch_toggle:
				crouch()
				
	# Add the gravity.
	var _acceleration
	if not is_on_floor():
		_acceleration = acceleration*air_acceleration_modifier
		
		if coyote_timer.is_stopped():
			coyote_timer.start(coyote_time)
	
		if velocity.y>0:
			velocity.y -= jump_gravity * _delta
		else:
			velocity.y -= fall_gravity * _delta
	else:
		_acceleration = acceleration
		jump_available = true
		coyote_timer.stop()
		_speed = (base_speed / max((float(crouched)*crouch_speed_reduction),1)) * speed_modifier
		if jump_buffer:
			jump()
			jump_buffer = false
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept"):
		if jump_available:
			if crouched:
				crouch()
			else:
				lean(CENTRE)
				jump()
		else:
			jump_buffer = true
			get_tree().create_timer(jump_buffer_time).timeout.connect(on_jump_buffer_timeout)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = move_toward(velocity.x, direction.x * _speed, _acceleration*_delta)
	velocity.z = move_toward(velocity.z, direction.z * _speed, _acceleration*_delta)
	
	move_and_slide()

func jump()->void:
	velocity.y = jump_velocity
	jump_available = false

func _on_sprint_timer_timeout() -> void:
	sprint_on_cooldown = true
	get_tree().create_timer(sprint_cooldown_time).timeout.connect(_on_sprint_cooldown_timeout)
	speed_modifier = NORMAL_speed
	sprint_time_remaining = 0

func _on_sprint_cooldown_timeout():
	sprint_on_cooldown = false

func _on_coyote_timer_timeout() -> void:
	jump_available = false

func on_jump_buffer_timeout()->void:
	jump_buffer = false

## Take damage - compatible with enemy weapon systems
func take_damage(damage: float, source: Node = null) -> void:
	if is_dead:
		return
	
	current_health -= damage
	current_health = max(current_health, 0.0)
	
	# Reset health regen timer
	health_regen_timer = 0.0
	
	_update_health_display()
	player_damaged.emit(current_health, max_health)
	
	if current_health <= 0 and not is_dead:
		_die()

## Hit_Successful method - required for compatibility with existing weapon system
func Hit_Successful(damage: float, _Direction: Vector3 = Vector3.ZERO, _Position: Vector3 = Vector3.ZERO) -> void:
	take_damage(damage)
	
	# Optional: Add knockback or screen shake effects here
	if _Direction != Vector3.ZERO:
		var knockback_force = _Direction * damage * 0.05
		velocity += Vector3(knockback_force.x, 0, knockback_force.z)

## Apply knockback to player (called by some enemy attacks)
func apply_knockback(knockback_vector: Vector3) -> void:
	velocity += knockback_vector

## Update health display
func _update_health_display() -> void:
	# Try to find health bar or health label in HUD
	var health_bar = get_node_or_null("CanvasLayer/HealthBar")
	if health_bar and health_bar is Range:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	var health_label = get_node_or_null("CanvasLayer/HealthLabel")
	if health_label and health_label is Label:
		health_label.text = "Health: " + str(int(current_health)) + "/" + str(int(max_health))

## Called when player dies
func _die() -> void:
	is_dead = true
	player_died.emit()
	
	# Disable player controls
	set_physics_process(false)
	
	# Optional: Add death effects, respawn logic, or game over screen
	print("Player died!")

## Get current health percentage (0.0 to 1.0)
func get_health_percentage() -> float:
	return current_health / max_health

## Check if player is alive
func is_alive() -> bool:
	return not is_dead

## Heal player
func heal(amount: float) -> void:
	if is_dead:
		return
	
	current_health = min(current_health + amount, max_health)
	_update_health_display()
