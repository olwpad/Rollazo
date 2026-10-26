# Barra arriba en el centro: de la salida a la bandera, con un punto del color de cada moco.
# recorrido.gd le da la ruta del mapa (salida, controles y meta) y, cada frame, dónde va cada uno.
# Las posiciones ya llegan a todos los PCs por el Sync, así que no manda nada por la red.
class_name BarraProgreso
extends Control

var ruta := PackedVector2Array()
var _puntos := []  # [[color, fraccion, es_el_mio], ...]


# Cuánto del camino lleva quien está en `pos`, de 0 (salida) a 1 (meta): el punto de la ruta
# más cercano a él, medido a lo largo de la ruta.
static func fraccion(ruta_mapa: PackedVector2Array, pos: Vector2) -> float:
	var total := 0.0
	var mejor := INF
	var recorrido_mejor := 0.0
	for i in range(1, ruta_mapa.size()):
		var a := ruta_mapa[i - 1]
		var b := ruta_mapa[i]
		var cerca := Geometry2D.get_closest_point_to_segment(pos, a, b)
		var d := pos.distance_to(cerca)
		if d < mejor:
			mejor = d
			recorrido_mejor = total + a.distance_to(cerca)
		total += a.distance_to(b)
	return 0.0 if total == 0.0 else clampf(recorrido_mejor / total, 0.0, 1.0)


func poner(puntos: Array) -> void:
	_puntos = puntos
	queue_redraw()


func _draw() -> void:
	var y := size.y - 14.0  # arriba queda sitio para la marca del mío
	var ancho := size.x - 30.0  # a la derecha, la bandera
	_pildora(Vector2(0, y), Vector2(ancho, y), 9.0, Color("fffaf4", 0.9))
	for p: Array in _puntos:  # lo que llevo, relleno de mi color
		if p[2] and p[1] > 0.0:
			_pildora(Vector2(0, y), Vector2(ancho * p[1], y), 6.0, Color(p[0], 0.55))
	_bandera(Vector2(ancho + 12.0, y))
	for p: Array in _puntos:  # el mío llega el último: queda encima
		var c := Vector2(ancho * p[1], y)
		draw_circle(c + Vector2(0, 2), 12.0 if p[2] else 9.0, Color(Acuarela.CIRUELA, 0.15))  # sombra
		draw_circle(c, 12.0 if p[2] else 9.0, Color("fffaf4"))
		draw_circle(c, 9.0 if p[2] else 6.5, p[0])
		if p[2]:  # triangulito encima: "este eres tú"
			draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -24), c + Vector2(7, -24), c + Vector2(0, -15)]), p[0])


func _pildora(a: Vector2, b: Vector2, radio: float, color: Color) -> void:
	draw_line(a, b, color, radio * 2.0)
	draw_circle(a, radio, color)
	draw_circle(b, radio, color)


func _bandera(pie: Vector2) -> void:
	draw_line(pie + Vector2(0, 8), pie + Vector2(0, -26), Acuarela.CIRUELA, 2.5, true)
	for fila in 2:  # cuadros 2x3, como la bandera de meta
		for col in 3:
			var color := Acuarela.CIRUELA if (fila + col) % 2 == 0 else Color("fffaf4")
			draw_rect(Rect2(pie + Vector2(1 + col * 6, -26 + fila * 6), Vector2(6, 6)), color)
