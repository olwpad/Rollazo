// Cielo nocturno de neón: degradado morado a rosa, luna y puntitos de cómic.
shader_type canvas_item;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = mix(vec3(0.12, 0.03, 0.30), vec3(1.0, 0.18, 0.53), smoothstep(0.05, 1.0, uv.y));
	vec2 aspecto = vec2(16.0 / 9.0, 1.0);
	if (distance(uv * aspecto, vec2(0.78, 0.22) * aspecto) < 0.1) {
		col = vec3(1.0, 0.88, 0.3);
	}
	vec2 punto = fract(FRAGCOORD.xy / 9.0) - 0.5;
	if (length(punto) < uv.y * 0.38) {
		col *= 0.8;
	}
	COLOR = vec4(col, 1.0);
}
