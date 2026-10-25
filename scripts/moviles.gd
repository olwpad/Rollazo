# Dónde ponen los temas sus enganchables que se mueven (barcos, lianas, ropa, globos). Todo sale
# de la semilla y del mapa, sin tocar el generador; si la zona que recorrería choca con el
# mapa, ese elemento no se pone (mejor uno menos que uno que tape el camino).
class_name Moviles
extends RefCounted

const VELOCIDAD_GLOBO := 70.0  # px/s: despacio, para engancharse con calma


# true si en `zona` hay una pieza del mapa, un control, una burbuja, un aro, una sierra, la salida o la meta
static func ocupado(m: Dictionary, zona: Rect2) -> bool:
	for p: Dictionary in m.piezas:
		var caja := Rect2(p.pos + p.poly[0], Vector2.ZERO)
		for v: Vector2 in p.poly:
			caja = caja.expand(p.pos + v)
		if caja.intersects(zona):
			return true
	var puntos: Array = m.controles + [m.inicio, m.meta]
	for lista: Array in [m.burbujas, m.aros, m.sierras]:
		puntos += lista.map(func(o: Dictionary) -> Vector2: return o.pos)
	return puntos.any(func(v: Vector2) -> bool: return zona.grow(60.0).has_point(v))


static func _rng(semilla: int, n: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, n))
	return rng


static func superficie_y(m: Dictionary) -> float:
	return maxf(m.caida_y - 300.0, m.limites.end.y)  # la misma que usa recorrido para pintar las olas


# Barcos que van y vienen por el agua: {pos (en la línea de agua), riel (cuánto recorren), fase}.
static func barcos(m: Dictionary, semilla: int) -> Array:
	var rng := _rng(semilla, 11)
	var n := clampi(int(m.limites.size.x / 2400.0), 2, 5)
	var hueco: float = m.limites.size.x / n
	var salida := []
	for i in n:
		var x: float = m.limites.position.x + (i + rng.randf_range(0.0, 0.2)) * hueco
		var b := {"pos": Vector2(x, superficie_y(m)), "riel": hueco * 0.75, "fase": rng.randf()}
		if not ocupado(m, Rect2(x - 70.0, b.pos.y - 170.0, b.riel + 140.0, 200.0)):
			salida.append(b)
	return salida


# Lianas colgando entre dos techos seguidos del camino: {pivote, largo, fase}.
static func lianas(m: Dictionary, semilla: int) -> Array:
	var rng := _rng(semilla, 12)
	var salida := []
	for i in range(1, m.camino.size()):
		var a: Vector2 = m.camino[i - 1]
		var b: Vector2 = m.camino[i]
		var l := {"pivote": Vector2((a.x + b.x) / 2.0, minf(a.y, b.y) - 60.0), "largo": rng.randf_range(150.0, 210.0), "fase": rng.randf()}
		if rng.randf() < 0.45 and not ocupado(m, Rect2(l.pivote.x - 110.0, l.pivote.y - 30.0, 220.0, l.largo + 60.0)):
			salida.append(l)
	return salida


# Cuerdas de ropa entre dos techos seguidos: {a, b (extremos), fase}; las prendas cuelgan de ella.
static func ropas(m: Dictionary, semilla: int) -> Array:
	var rng := _rng(semilla, 13)
	var salida := []
	for i in range(1, m.camino.size()):
		var a: Vector2 = m.camino[i - 1]
		var b: Vector2 = m.camino[i]
		var x := (a.x + b.x) / 2.0
		var y := minf(a.y, b.y) - 20.0
		var r := {"a": Vector2(x - 80.0, y), "b": Vector2(x + 80.0, y + 6.0), "fase": rng.randf()}
		if rng.randf() < 0.4 and not ocupado(m, Rect2(x - 90.0, y - 20.0, 180.0, 130.0)):
			salida.append(r)
	return salida


# Globos que suben por el hueco entre dos techos: {x, abajo (y de salida), alto, fase}, como mucho 6.
static func globos(m: Dictionary, semilla: int) -> Array:
	var rng := _rng(semilla, 14)
	var abajo: float = m.limites.end.y - 100.0
	var alto: float = m.limites.size.y - 300.0
	var salida := []
	for i in range(1, m.camino.size()):
		var x0: float = (m.camino[i - 1].x + m.camino[i].x) / 2.0
		var g := {"abajo": abajo, "alto": alto, "fase": rng.randf()}
		var quiere := rng.randf() < 0.5 and salida.size() < 6
		for dx in [0.0, 200.0, -200.0]:  # si el hueco de en medio está tapado, uno al lado
			g.x = x0 + dx
			if quiere and not ocupado(m, Rect2(g.x - 60.0, abajo - alto, 120.0, alto)):
				salida.append(g)
				break
	return salida


# Mancha de acuarela dentro de un _draw: base opaca y capas translúcidas, como las piezas del mapa
# pero con menos temblor (Acuarela.pintar rompe los polígonos pequeños).
static func mancha(lienzo: CanvasItem, poly: PackedVector2Array, color: Color, semilla: int) -> void:
	lienzo.draw_colored_polygon(Tinta.irregular(poly, semilla, 1.0, 30.0), color.lightened(0.35))
	for k in 3:
		lienzo.draw_colored_polygon(Tinta.irregular(poly, semilla * 3 + k, 1.6 - k * 0.5, 30.0), Color(color, Acuarela.OPACIDAD_CAPA))


static func elipse(rx: float, ry: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 16:
		p.append(Vector2(cos(TAU * i / 16.0) * rx, sin(TAU * i / 16.0) * ry))
	return p
