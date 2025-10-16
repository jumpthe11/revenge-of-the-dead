extends MeshInstance3D
class_name BulletTrail

## Performance-optimized bullet trail for visual feedback
## Uses simple line mesh with gradient fade-out

@export var trail_width: float = 0.02
@export var trail_lifetime: float = 0.15  # How long trail stays visible
@export var trail_color: Color = Color(1.0, 0.8, 0.3, 1.0)  # Yellow-ish bullet color
@export var bullet_speed: float = 500.0  # Simulated bullet speed in m/s

var start_position: Vector3
var end_position: Vector3
var target_position: Vector3
var elapsed_time: float = 0.0
var travel_time: float = 0.0
var is_traveling: bool = false
var shader_material: ShaderMaterial
var trail_shader: Shader

func _ready() -> void:
	_setup_shader_material()

func setup_trail(from: Vector3, to: Vector3) -> void:
	start_position = from
	end_position = to
	target_position = to
	global_position = Vector3.ZERO  # Use world space
	
	# Calculate travel time
	var distance = from.distance_to(to)
	if distance > 0.001:
		travel_time = distance / bullet_speed
		is_traveling = true
		# Create full mesh once from barrel to target
		_create_trail_mesh()
		# Start with progress at 0 (nothing visible yet)
		if shader_material:
			shader_material.set_shader_parameter("travel_progress", 0.0)
			shader_material.set_shader_parameter("fade_alpha", 1.0)

func _setup_shader_material() -> void:
	# Load shader and create material
	if not trail_shader:
		trail_shader = load("res://Player_Controller/scripts/Projectiles/bullet_trail.gdshader")
	
	if not shader_material:
		shader_material = ShaderMaterial.new()
		shader_material.shader = trail_shader
		# Set default parameters
		shader_material.set_shader_parameter("travel_progress", 1.0)
		shader_material.set_shader_parameter("fade_alpha", 1.0)
		shader_material.set_shader_parameter("trail_color", trail_color)

func _create_trail_mesh() -> void:
	# Only create if trail has length
	if start_position.distance_to(end_position) < 0.001:
		return
	
	# Clear existing mesh if any
	if mesh:
		mesh = null
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Calculate perpendicular vector for width
	var direction = (end_position - start_position).normalized()
	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var perpendicular = direction.cross(up).normalized() * trail_width * 0.5
	
	# Store position along trail in vertex alpha (0.0=barrel, 1.0=bullet)
	# Shader uses this to animate the reveal
	var barrel_color = Color(1.0, 1.0, 1.0, 0.0)  # Alpha=0.0 = barrel position
	var bullet_color = Color(1.0, 1.0, 1.0, 1.0)  # Alpha=1.0 = bullet position
	
	# First triangle
	surface_tool.set_color(barrel_color)
	surface_tool.add_vertex(start_position + perpendicular)
	surface_tool.set_color(barrel_color)
	surface_tool.add_vertex(start_position - perpendicular)
	surface_tool.set_color(bullet_color)
	surface_tool.add_vertex(end_position - perpendicular)
	
	# Second triangle
	surface_tool.set_color(barrel_color)
	surface_tool.add_vertex(start_position + perpendicular)
	surface_tool.set_color(bullet_color)
	surface_tool.add_vertex(end_position - perpendicular)
	surface_tool.set_color(bullet_color)
	surface_tool.add_vertex(end_position + perpendicular)
	
	mesh = surface_tool.commit()
	
	# Apply shader material
	if mesh and shader_material:
		set_surface_override_material(0, shader_material)

func _process(delta: float) -> void:
	# Safety check - don't process if not visible
	if not visible:
		set_process(false)
		return
	
	elapsed_time += delta
	
	# Animate bullet travel (shader-based - no mesh recreation!)
	if is_traveling:
		var travel_progress = min(elapsed_time / travel_time, 1.0)
		# Update shader uniform only - super performant!
		if shader_material:
			shader_material.set_shader_parameter("travel_progress", travel_progress)
		
		if travel_progress >= 1.0:
			is_traveling = false
			elapsed_time = 0.0  # Reset for fade phase
		return
	
	# Fade out trail after reaching target
	var alpha = 1.0 - (elapsed_time / trail_lifetime)
	if alpha <= 0.0:
		set_process(false)
		_return_to_pool()
		return
	
	# Update shader fade during fade
	if shader_material:
		shader_material.set_shader_parameter("fade_alpha", alpha)

func _return_to_pool() -> void:
	# Return to BulletTrailManager pool
	if BulletTrailManager and BulletTrailManager.is_initialized:
		BulletTrailManager.return_trail(self)
	else:
		visible = false

func reset() -> void:
	elapsed_time = 0.0
	travel_time = 0.0
	is_traveling = false
	start_position = Vector3.ZERO
	end_position = Vector3.ZERO
	target_position = Vector3.ZERO
	# Ensure shader material exists
	if not shader_material:
		_setup_shader_material()
	if shader_material:
		shader_material.set_shader_parameter("travel_progress", 1.0)
		shader_material.set_shader_parameter("fade_alpha", 1.0)
		shader_material.set_shader_parameter("trail_color", trail_color)
