shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// Two-colour vertical gradient with optional stars. UV.y is 0 at the top of the quad.
uniform vec4 top_color : source_color = vec4(0.310, 0.659, 0.878, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.749, 0.902, 0.969, 1.0);
uniform float star_amount : hint_range(0.0, 1.0) = 0.0;

// Number of star cells across the quad. Higher gives smaller stars.
const float STAR_CELLS = 220.0;
// Share of cells that hold a star when star_amount is 1.0.
const float STAR_DENSITY = 0.012;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = 1.0 - UV.y;
	vec3 col = mix(bottom_color.rgb, top_color.rgb, t);
	if (star_amount > 0.0) {
		vec2 cell = floor(UV * STAR_CELLS);
		if (hash(cell) > 1.0 - STAR_DENSITY * star_amount) {
			col = vec3(1.0);
		}
	}
	ALBEDO = col;
}
