# Trampolín: colchón con muelles bajo un hueco entre dos techos. Quién rebota lo decide el
# anfitrión (recorrido.gd) cuando un moco entra cayendo; aquí hay sitio, forma, rebote y dibujo.
# El aplastón sale de `rebotar()`, que el anfitrión manda por rpc a todos los PCs.
class_name Trampolin
extends Area2D

const ANCHO := 140.0
const REBOTE_MIN := 1150.0  # px/s hacia arriba, aunque caigas despacio
const REBOTE_MAX := 1300.0  # tope: con más, una caída desde lejos te mandaría al cielo prohibido
const FACTOR := 1.05  # sale un poco más rápido de lo que entró
const SEGUNDOS_APLASTAR := 0.6

var nivel: Node = null
var _rebote_ms := -100000


# Velocidad vertical (negativa = hacia arriba) al rebotar cayendo a `vy` px/s.
static func velocidad_rebote(vy: float) -> float:
	return -clampf(absf(vy) * FACTOR, REBOTE_MIN, REBOTE_MAX)


# 1 o 2 por mapa, bajo el hueco entre dos techos seguidos de un tramo horizontal o de bajada, a la
# altura del suelo: ahí pasa el moco que se cae. Si no cabe o choca con un ventilador, no se pone.
static func nuevos(semilla: int, m: Dictionary, nivel_: Node) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 62))
	var huecos := []
	for t: Dictionary in m.tramos:
		if t.tipo in ["horizontal", "bajada"]:
			for i in range(t.i0 + 1, t.i1):
				huecos.append([m.camino[i - 1], m.camino[i]])
	var zonas: Array[Rect2] = []
	for v: Ventilador in Ventilador.nuevos(semilla, m, null):
		zonas.append(v.zona())
		v.free()
	var lista := []
	var quiere := rng.randi_range(1, 2)
	for intento in 30:
		if lista.size() >= quiere or huecos.is_empty():
			break
		var h: Array = huecos[rng.randi_range(0, huecos.size() - 1)]
		var t := Trampolin.new()
		t.nivel = nivel_
		t.position = Vector2((h[0].x + h[1].x) / 2.0, maxf(h[0].y, h[1].y) + 330.0)
		var zona := t.zona()
		if not Moviles.ocupado(m, zona) and not zona.grow(400.0).has_point(m.inicio) and not zona.grow(400.0).has_point(m.meta) \
				and zonas.all(func(z: Rect2) -> bool: return not z.grow(100.0).intersects(zona)):
			t.name = "Trampolin%d" % lista.size()
			lista.append(t)
			zonas.append(zona)
		else:
			t.free()
	return lista


# Colchón, muelles y base (coordenadas globales). `position` es la cara de arriba del colchón.
func zona() -> Rect2:
	return Rect2(position + Vector2(-ANCHO / 2.0 - 10.0, -20.0), Vector2(ANCHO + 20.0, 100.0))


func rebotar() -> void:
	_rebote_ms = Time.get_ticks_msec()
	queue_redraw()


func _ready() -> void:
	collision_mask = 2  # solo mocos
	var forma := CollisionShape2D.new()
	forma.shape = RectangleShape2D.new()
	forma.shape.size = Vector2(ANCHO, 40.0)
	forma.position = Vector2(0, 2)
	add_child(forma)


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - _rebote_ms < SEGUNDOS_APLASTAR * 1000.0 + 50.0:
		queue_redraw()  # solo mientras se aplasta: el resto del tiempo está quieto


# Cuánto se aplasta (0 = nada, 1 = a tope): se hunde y vuelve oscilando.
static func aplastado(segundos: float) -> float:
	if segundos < 0.0 or segundos > SEGUNDOS_APLASTAR:
		return 0.0
	return absf(sin(segundos / SEGUNDOS_APLASTAR * TAU * 1.5)) * (1.0 - segundos / SEGUNDOS_APLASTAR)


func _draw() -> void:
	var a := aplastado((Time.get_ticks_msec() - _rebote_ms) / 1000.0)
	var hundido := a * 22.0
	var alto_muelle := 36.0 - hundido
	# Base y muelles (zigzag que se comprime)
	draw_rect(Rect2(-ANCHO / 2.0 + 10.0, 22.0 + 36.0, ANCHO - 20.0, 9.0), Acuarela.LAVANDA.darkened(0.15))
	for lado in [-1.0, 1.0]:
		var zig := PackedVector2Array()
		for k in 7:
			zig.append(Vector2(lado * (ANCHO / 2.0 - 30.0) + (k % 2 * 2 - 1) * 9.0, 22.0 + hundido + alto_muelle * k / 6.0))
		draw_polyline(zig, Acuarela.LAVANDA, 4.0)
	# Colchón melocotón con dos costuras crema, que se hunde por el centro
	var colchon := PackedVector2Array([Vector2(-ANCHO / 2.0, hundido * 0.4), Vector2(0, hundido), Vector2(ANCHO / 2.0, hundido * 0.4),
			Vector2(ANCHO / 2.0, 22.0 + hundido * 0.4), Vector2(0, 22.0 + hundido), Vector2(-ANCHO / 2.0, 22.0 + hundido * 0.4)])
	Moviles.mancha(self, colchon, Color("f5b38a"), 62)
	for x in [-ANCHO / 4.0, ANCHO / 4.0]:
		draw_line(Vector2(x, 5.0 + hundido * 0.7), Vector2(x, 17.0 + hundido * 0.7), Color("fffaf4", 0.8), 3.0)
