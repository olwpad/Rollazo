# Mandíbula: un muro altísimo en dos mitades (arriba y abajo) que se separan cada cierto tiempo y
# se vuelven a cerrar. No se pasa por encima ni por debajo; el que se queda en el hueco al cerrarse
# se lleva el "¡ÑAM!". Las mitades se mueven solo con `nivel.reloj_ronda` (igual en todos los PCs);
# el anfitrión decide el mordisco (recorrido.gd, vía la señal `mordio`).
class_name Puerta
extends Node2D

signal mordio(cuerpo: Node2D)

const ANCHO := 56.0
const HUECO := 260.0  # alto del hueco con la puerta abierta del todo
const PERIODO := 5.0
const ABRIENDO := 0.5
const ABIERTA := 2.5
const CERRANDO := 0.5  # el resto del periodo (1,5 s) está cerrada
const LETAL := 0.3  # con menos abertura que esto (~80 px de hueco) el moco no cabe: ¡ñam!
const DIENTE_ALTO := 24.0
const VISTA := 2200.0  # lo que se dibuja de cada mitad desde su borde; la colisión llega mucho más lejos

var fase := 0.0  # en vueltas (0..1)
var arriba_y := 0.0  # globales: hasta dónde llegan las mitades
var abajo_y := 0.0
var color := Color("7d74b8")
var nivel: Node = null
var _mitades: Array[Mitad] = []
var _zona := Area2D.new()


# Cuánto está abierta (0 = cerrada, 1 = del todo) en el segundo `t` de su ciclo.
static func abertura_en(t: float) -> float:
	var s := fposmod(t, PERIODO)
	if s < ABRIENDO:
		return s / ABRIENDO
	if s < ABRIENDO + ABIERTA:
		return 1.0
	if s < ABRIENDO + ABIERTA + CERRANDO:
		return 1.0 - (s - ABRIENDO - ABIERTA) / CERRANDO
	return 0.0


# 1 o 2 puertas por mapa, solo en ~1 de cada 3 (si tiene tramos horizontal o de bajada), en el hueco entre
# dos techos seguidos, donde pasa el columpio. Nunca pegadas a un ventilador ni a un trampolín.
static func nuevas(semilla: int, m: Dictionary, nivel_: Node) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 65))
	var huecos := []  # índice del segundo techo de cada hueco
	for t: Dictionary in m.tramos:
		if t.tipo in ["horizontal", "bajada"]:
			for i in range(t.i0 + 2, t.i1):  # el primer hueco de un tramo sigue a un descanso o a la salida
				huecos.append(i)
	var lista := []
	if huecos.is_empty() or rng.randf() >= 0.6:
		return lista
	var otras: Array[Rect2] = []
	for v: Ventilador in Ventilador.nuevos(semilla, m, null):
		otras.append(v.zona())
		v.free()
	for t: Trampolin in Trampolin.nuevos(semilla, m, null):
		otras.append(t.zona())
		t.free()
	var elegidos := []
	var quiere := rng.randi_range(1, 2)
	for intento in 20:
		if elegidos.size() >= quiere:
			break
		var i: int = huecos[rng.randi_range(0, huecos.size() - 1)]
		var a: Vector2 = m.camino[i - 1]
		var b: Vector2 = m.camino[i]
		var pos := Vector2((a.x + b.x) / 2.0, minf(a.y, b.y) + 200.0)
		var arriba: float = m.limites.position.y - 2000.0
		var columna := Rect2(pos.x - ANCHO / 2.0, arriba, ANCHO, m.caida_y - arriba)
		if pos.distance_to(m.inicio) >= 500.0 and pos.distance_to(m.meta) >= 500.0 \
				and elegidos.all(func(j: int) -> bool: return absi(j - i) > 1) \
				and not Moviles.ocupado(m, columna) \
				and otras.all(func(z: Rect2) -> bool: return not z.grow(100.0).intersects(columna)):
			elegidos.append(i)
			var p := Puerta.new()
			p.name = "Puerta%d" % lista.size()
			p.position = pos
			p.fase = rng.randf()
			p.arriba_y = arriba
			p.abajo_y = m.caida_y
			p.nivel = nivel_
			lista.append(p)
	return lista


func _ready() -> void:
	for esta_arriba in [true, false]:
		var mitad := Mitad.new()
		mitad.arriba = esta_arriba
		mitad.alto = (position.y - arriba_y) if esta_arriba else (abajo_y - position.y)
		mitad.color = color
		mitad.sync_to_physics = true
		add_child(mitad)
		_mitades.append(mitad)
	# Detector de lo que queda entre las mitades; más estrecho que el muro para que no cuente quien lo roza
	_zona.collision_mask = 2  # solo mocos
	var forma := CollisionShape2D.new()
	forma.shape = RectangleShape2D.new()
	forma.shape.size = Vector2(ANCHO - 16.0, HUECO)
	_zona.add_child(forma)
	add_child(_zona)
	_mover(0.0)


func _physics_process(_delta: float) -> void:
	var a := _mover(nivel.reloj_ronda if nivel != null else 0.0)
	if multiplayer.is_server() and a < LETAL:
		for c in _zona.get_overlapping_bodies():
			if c is Jugador and not c.congelado:
				mordio.emit(c)


func _mover(t: float) -> float:
	var a := abertura_en(t + fase * PERIODO)
	var medio := HUECO * a / 2.0
	_mitades[0].position.y = -medio
	_mitades[1].position.y = medio
	return a


# Una mitad: cuerpo que se mueve (empuja a los mocos) y dibujo de acuarela con dientes en el borde del hueco.
class Mitad extends AnimatableBody2D:
	var arriba := true
	var alto := 1000.0  # de colisión
	var color := Color("7d74b8")

	func _ready() -> void:
		var forma := CollisionShape2D.new()
		forma.shape = RectangleShape2D.new()
		forma.shape.size = Vector2(ANCHO, alto)
		forma.position.y = (-1.0 if arriba else 1.0) * alto / 2.0
		add_child(forma)

	func _draw() -> void:
		var s := -1.0 if arriba else 1.0  # hacia dónde crece la mitad
		var v := minf(alto, VISTA)
		var cuerpo := PackedVector2Array([Vector2(-ANCHO / 2.0, 0), Vector2(ANCHO / 2.0, 0), Vector2(ANCHO / 2.0, s * v), Vector2(-ANCHO / 2.0, s * v)])
		Moviles.mancha(self, cuerpo, color, 65 if arriba else 66)
		var y := 70.0
		while y < v:  # rayas crema, apenas visibles
			draw_line(Vector2(-ANCHO / 2.0 + 4.0, s * y), Vector2(ANCHO / 2.0 - 4.0, s * y), Color("fffaf4", 0.16), 3.0)
			y += 70.0
		# Dientes hacia el hueco; los de abajo desplazados medio diente para que encajen con los de arriba
		var n := 3
		var d := ANCHO / n
		var desfase := 0.0 if arriba else d / 2.0
		for k in n:
			var x0 := -ANCHO / 2.0 + k * d + desfase
			var diente := PackedVector2Array([Vector2(x0, 0), Vector2(x0 + d, 0), Vector2(x0 + d / 2.0, -s * DIENTE_ALTO)])
			draw_colored_polygon(diente, Color("fffaf4", 0.95))
