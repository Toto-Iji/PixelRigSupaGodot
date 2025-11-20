shader_type canvas_item;

uniform float edge_softness = 0.05;

void fragment() {
	vec2 uv = UV;
	
	// Calculate distance from edges (0.0 at edges, 0.5 at center)
	float dist_x = min(uv.x, 1.0 - uv.x);
	float dist_y = min(uv.y, 1.0 - uv.y);
	float edge_dist = min(dist_x, dist_y);
	
	// Smooth fade at edges
	float alpha = smoothstep(0.0, edge_softness, edge_dist);
	
	COLOR = vec4(0.0, 0.0, 0.0, alpha * 0.5);
}