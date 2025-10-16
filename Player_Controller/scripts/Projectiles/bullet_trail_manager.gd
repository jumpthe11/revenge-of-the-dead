extends Node

## Singleton manager for bullet trail pooling and performance optimization
## Prevents constant creation/destruction of trail nodes

@export var pool_size: int = 50  # Pre-instantiated trails
@export var max_active_trails: int = 100  # Maximum active trails at once

var trail_pool: Array[BulletTrail] = []
var active_trails: Array[BulletTrail] = []
var trail_scene: PackedScene
var is_initialized: bool = false

func _ready() -> void:
	# Load trail scene
	trail_scene = preload("res://Player_Controller/Spawnable_Objects/bullet_trail.tscn")
	_initialize_pool()
	is_initialized = true

func _initialize_pool() -> void:
	for i in pool_size:
		var trail = _create_new_trail()
		trail.visible = false
		trail.set_process(false)  # Disable processing until used
		add_child(trail)
		trail_pool.append(trail)

func _create_new_trail() -> BulletTrail:
	var trail: BulletTrail
	if trail_scene:
		trail = trail_scene.instantiate()
	else:
		# Fallback: create trail directly
		trail = BulletTrail.new()
	return trail

## Spawn a bullet trail from start to end position
func spawn_trail(from: Vector3, to: Vector3, color: Color = Color(1.0, 0.8, 0.3, 1.0)) -> void:
	if not is_initialized:
		return
	
	var trail: BulletTrail
	
	# Try to get from pool first
	if not trail_pool.is_empty():
		trail = trail_pool.pop_back()
		# Validate pooled trail
		if not trail or not is_instance_valid(trail):
			trail = null
	
	# If no valid trail from pool, check if we need to recycle or create new
	if not trail:
		if active_trails.size() >= max_active_trails:
			# Recycle oldest trail
			if active_trails.size() > 0:
				trail = active_trails[0]
				active_trails.remove_at(0)
				if not trail or not is_instance_valid(trail):
					return
		else:
			# Create new trail
			trail = _create_new_trail()
			if not trail:
				return
			add_child(trail)
	
	# Final validation
	if not trail or not is_instance_valid(trail):
		return
	
	# Setup and activate trail
	trail.reset()
	trail.trail_color = color
	trail.setup_trail(from, to)
	trail.visible = true
	trail.set_process(true)  # Enable processing
	active_trails.append(trail)

## Return trail to pool
func return_trail(trail: BulletTrail) -> void:
	if not trail or not is_instance_valid(trail):
		return
	
	# Remove from active trails
	active_trails.erase(trail)
	
	# Clean up trail state
	trail.visible = false
	trail.set_process(false)  # Disable processing
	trail.elapsed_time = 0.0
	
	# Return to pool if under pool size limit
	if trail_pool.size() < pool_size:
		# Only add to pool if not already there
		if not trail in trail_pool:
			trail_pool.append(trail)
	else:
		# Destroy if pool is full
		trail.queue_free()

## Clear all active trails (useful for scene transitions)
func clear_all_trails() -> void:
	for trail in active_trails:
		return_trail(trail)
	active_trails.clear()
