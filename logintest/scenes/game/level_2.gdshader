shader_type canvas_item;

uniform float edge_softness = 0.2;
uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;  // ← NEW

void fragment() {
	vec2 uv = UV;
	
	// Create soft edge on the left side (where door is)
	float edge = smoothstep(0.0, edge_softness, uv.x - reveal_progress);
	
	COLOR = vec4(0.0, 0.0, 0.0, edge * 0.9);
}
