shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform float growth = 0.0;
uniform vec3 ring_color : source_color = vec3(1.0, 0.62, 0.25);
uniform vec3 hot_color : source_color = vec3(1.0, 0.95, 0.8);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float hole = 0.28 + 0.5 * growth;

	// Ring part: flatten the disc by scaling y before the distance.
	vec2 fp = vec2(p.x, p.y * 1.6);
	float rr = length(fp);

	float falloff = 1.0 - smoothstep(hole, hole * 2.2, rr);
	float swirl = 0.75 + 0.25 * sin(a * 6.0 + rr * 18.0 - TIME * 1.5);
	float bright = falloff * swirl;

	// Thin bright rim at the hole edge.
	float rim = 1.0 - smoothstep(0.0, 0.02, abs(r - hole));

	// Black hole core: round, fully opaque.
	float inside = 1.0 - smoothstep(hole - 0.01, hole, r);

	vec3 col = mix(ring_color, hot_color, bright);
	col = mix(col, hot_color, rim);
	col = mix(col, vec3(0.0), inside);

	ALBEDO = col;
	ALPHA = max(max(inside, bright), rim);
}
