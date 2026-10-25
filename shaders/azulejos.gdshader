// Pared de baño en azulejos con puntitos de cómic (halftone) que crecen hacia abajo.
shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.93, 0.97, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.78, 0.89, 0.98, 1.0);
uniform vec4 color_junta : source_color = vec4(0.55, 0.72, 0.88, 1.0);
uniform float tam_azulejo = 96.0;

varying vec2 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 celda = mundo / tam_azulejo;
	vec2 f = fract(celda);
	vec4 col = mod(floor(celda.x) + floor(celda.y), 2.0) < 1.0 ? color_a : color_b;
	if (min(f.x, f.y) < 0.04) {
		col = color_junta;
	}
	vec2 punto = fract(mundo / 14.0) - 0.5;
	float radio = clamp((mundo.y - 150.0) / 1300.0, 0.0, 1.0) * 0.42;
	if (length(punto) < radio) {
		col.rgb *= 0.86;
	}
	COLOR = col;
}
