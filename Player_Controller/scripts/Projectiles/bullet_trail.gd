extends MeshInstance3D
class_name BulletTrail

## Performance-optimized bullet trail for visual feedback
## Uses simple line mesh with gradient fade-out

@export var trail_width: float = 0.02
@export var trail_lifetime: float = 0.15  # How long trail stays visible
@export var trail_color: Color = Color(1.0, 0.8, 0.3, 1.0)  # Yellow-ish bullet color

var start_position: Vector3
var end_position: Vector3
var elapsed_time: float = 0.0
var material: StandardMaterial3D

func _ready() -> void:
	_setup_material()

func setup_trail(from: Vector3, to: Vector3) -> void:
	start_position = from
	end_position = to
	global_position = Vector3.ZERO  # Use world space
	
	# Only create mesh if positions are valid and different
	if from.distance_to(to) > 0.001:
		_create_trail_mesh()

func _setup_material() -> void:
	# Create a unique material instance for this trail
	if not material:
		material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD  # Additive for glow effect
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.disable_receive_shadows = true
		material.no_depth_test = false

func _create_trail_mesh() -> void:
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
	
	# Create quad strip for the trail
	var start_color = trail_color
	var end_color = Color(trail_color.r, trail_color.g, trail_color.b, 0.0)  # Fade to transparent
	
	# First triangle
	surface_tool.set_color(start_color)
	surface_tool.add_vertex(start_position + perpendicular)
	surface_tool.set_color(start_color)
	surface_tool.add_vertex(start_position - perpendicular)
	surface_tool.set_color(end_color)
	surface_tool.add_vertex(end_position - perpendicular)
	
	# Second triangle
	surface_tool.set_color(start_color)
	surface_tool.add_vertex(start_position + perpendicular)
	surface_tool.set_color(end_color)
	surface_tool.add_vertex(end_position - perpendicular)
	surface_tool.set_color(end_color)
	surface_tool.add_vertex(end_position + perpendicular)
	
	mesh = surface_tool.commit()
	
	# Apply material after mesh is created
	if mesh and material:
		set_surface_override_material(0, material)

func _process(delta: float) -> void:
	# Safety check - don't process if not visible
	if not visible:
		set_process(false)
		return
	
	elapsed_time += delta
	
	# Fade out trail over its lifetime
	var alpha = 1.0 - (elapsed_time / trail_lifetime)
	if alpha <= 0.0:
		set_process(false)
		_return_to_pool()
		return
	
	# Update material transparency
	if material and is_instance_valid(material):
		material.albedo_color = Color(1.0, 1.0, 1.0, alpha)

func _return_to_pool() -> void:
	# Return to BulletTrailManager pool
	if BulletTrailManager and BulletTrailManager.is_initialized:
		BulletTrailManager.return_trail(self)
	else:
		visible = false

func reset() -> void:
	elapsed_time = 0.0
	start_position = Vector3.ZERO
	end_position = Vector3.ZERO
	# Ensure material exists and is valid
	if not material or not is_instance_valid(material):
		_setup_material()
	if material and is_instance_valid(material):
		material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
