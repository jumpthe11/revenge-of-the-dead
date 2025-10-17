shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

// Trail animation parameters
uniform float travel_progress : hint_range(0.0, 1.0) = 1.0;  // How far bullet has traveled (0=start, 1=end)
uniform float fade_alpha : hint_range(0.0, 1.0) = 1.0;       // Overall trail fade (for disappearing)
uniform float trail_length : hint_range(0.0, 1.0) = 0.3;     // Length of visible trail behind bullet (normalized)
uniform vec4 trail_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);

void vertex() {
	// Pass vertex color to fragment shader
	COLOR = COLOR;
}

void fragment() {
	// Get position along trail (0=barrel, 1=bullet tip)
	// This comes from vertex colors set during mesh creation
	float position_along_trail = COLOR.a;
	
	// Only show trail within trail_length distance behind bullet
	float trail_start = max(0.0, travel_progress - trail_length);
	if (position_along_trail > travel_progress || position_along_trail < trail_start) {
		discard;
	}
	
	// Gradient fade within the visible trail length
	float gradient_alpha = (position_along_trail - trail_start) / max(0.001, trail_length);
	
	// Apply both gradient and overall fade
	float final_alpha = gradient_alpha * fade_alpha;
	
	// Apply trail color with calculated alpha
	ALBEDO = trail_color.rgb;
	ALPHA = final_alpha;
}
