# Datos de los poderes y su dibujito blanco (el mismo en la burbuja del mapa y en el HUD).
# Solo constantes y funciones estáticas, como una clase de utilidades de Java.
class_name Poderes
extends RefCounted

const TIPOS := ["congelar", "rapidez", "pared", "salto", "punetazo"]
const DURACION := {"congelar": 2.5, "congelado": 2.5, "rapidez": 5.0, "pared": 6.0, "salto": 8.0, "punetazo": 6.0}
const NOMBRE := {"congelar": "CONGELAR", "congelado": "CONGELADO", "rapidez": "RAPIDEZ", "pared": "PARED",
		"salto": "SALTO ALTO", "punetazo": "PUÑETAZO"}
const COLOR := {"congelar": Color("8fd0e6"), "congelado": Color("8fd0e6"), "rapidez": Color("f2c27a"),
		"pared": Color("6cc3b0"), "salto": Color("a99be0"), "punetazo": Color("ef8fae")}
const BLANCO := Color("fffaf4")


# Copo, rayo, ventosa, muelle o puño, centrado en `c` y del tamaño de `r`.
static func dibujar_icono(lienzo: CanvasItem, tipo: String, c: Vector2, r: float) -> void:
	var g := r * 0.16  # grosor del trazo
	match tipo:
		"congelar", "congelado":
			for a in [0.0, PI / 3.0, -PI / 3.0]:
				var d := Vector2.UP.rotated(a) * r * 0.55
				lienzo.draw_line(c - d, c + d, BLANCO, g, true)
		"rapidez":
			lienzo.draw_polyline(PackedVector2Array([c + Vector2(-0.45, -0.4) * r, c + Vector2(0.1, -0.05) * r,
					c + Vector2(-0.1, 0.05) * r, c + Vector2(0.45, 0.4) * r]), BLANCO, g, true)
		"pared":
			lienzo.draw_line(c + Vector2(-0.35, 0.45) * r, c + Vector2(-0.35, -0.45) * r, BLANCO, g, true)
			lienzo.draw_arc(c + Vector2(0.05, -0.05) * r, r * 0.3, -PI / 2.0, PI / 2.0, 8, BLANCO, g, true)
		"salto":
			lienzo.draw_polyline(PackedVector2Array([c + Vector2(-0.35, 0.45) * r, c + Vector2(0.35, 0.25) * r,
					c + Vector2(-0.35, 0.05) * r, c + Vector2(0.35, -0.15) * r, c + Vector2(-0.35, -0.35) * r]), BLANCO, g, true)
		"punetazo":
			lienzo.draw_circle(c, r * 0.3, BLANCO)
			lienzo.draw_line(c + Vector2(-0.6, 0) * r, c + Vector2(-0.35, 0) * r, BLANCO, g, true)
			lienzo.draw_line(c + Vector2(0.35, 0) * r, c + Vector2(0.6, 0) * r, BLANCO, g, true)
