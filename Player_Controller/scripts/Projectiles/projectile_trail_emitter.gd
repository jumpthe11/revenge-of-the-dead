extends Node3D
class_name ProjectileTrailEmitter

## Trail emitter for rigid body projectiles
## Spawns trail segments as the projectile moves

@export var trail_color: Color = Color(1.0, 0.8, 0.3, 1.0)
@export var emit_interval: float = 0.02  # Spawn trail every 0.02 seconds
@export var min_distance: float = 0.1  # Minimum distance before spawning new trail

var last_position: Vector3
var time_since_last_emit: float = 0.0
var projectile_parent: Node3D

func _ready() -> void:
	projectile_parent = get_parent()
	last_position = global_position

func _process(delta: float) -> void:
	time_since_last_emit += delta
	
	# Check if enough time has passed and we've moved enough distance
	if time_since_last_emit >= emit_interval:
		var distance = global_position.distance_to(last_position)
		if distance >= min_distance:
			_emit_trail_segment()
			time_since_last_emit = 0.0

func _emit_trail_segment() -> void:
	if BulletTrailManager:
		BulletTrailManager.spawn_trail(last_position, global_position, trail_color)
	last_position = global_position
