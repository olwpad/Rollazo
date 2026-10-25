// Cielo de acuarela pastel: rosa arriba, lavanda y menta abajo, luna blanca difuminada y grano de papel.
shader_type canvas_item;

// Cada mapa pone sus colores (recorrido.gd); estos son los de la azotea de día.
uniform vec3 arriba = vec3(0.969, 0.839, 0.878);
uniform vec3 medio = vec3(0.788, 0.839, 0.949);
uniform vec3 abajo = vec3(0.914, 0.953, 0.945);
uniform float luna = 1.0;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = mix(arriba, medio, smoothstep(0.0, 0.6, uv.y));
	col = mix(col, abajo, smoothstep(0.6, 1.0, uv.y));
	// manchas suaves, como agua que se seca desigual
	col *= 1.0 - 0.04 * sin(uv.x * 9.0 + sin(uv.y * 7.0) * 2.0);
	vec2 aspecto = vec2(16.0 / 9.0, 1.0);
	float d = distance(uv * aspecto, vec2(0.78, 0.2) * aspecto);
	col = mix(col, vec3(1.0, 0.99, 0.97), (1.0 - smoothstep(0.07, 0.1, d)) * luna);
	col *= 0.96 + 0.04 * ruido(floor(FRAGCOORD.xy / 2.0));
	COLOR = vec4(col, 1.0);
}
