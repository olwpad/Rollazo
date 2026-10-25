# Genera un recorrido al azar a partir de una semilla. Con la misma semilla sale siempre
# el mismo mapa (como new Random(semilla) en Java), así los 4 PCs construyen lo mismo
# y solo hace falta mandar un número por la red.
#
# Reglas para que siempre se pueda pasar: los techos del camino van a 520-640 px uno del
# otro y a una altura que el papel alcanza; tras cada descanso, el techo siguiente queda a
# tiro desde el suelo. Lo demás (atajos, bloques, embudos) es extra.
class_name Generador
extends RefCounted

const LARGO := 7600.0  # a partir de aquí se pone la meta
const SUELO_Y := 690.0  # centro de los descansos (la parte de arriba queda en y=670)
const INICIO_FIN := 400.0  # donde acaba el suelo de salida


# Devuelve un Dictionary con:
#   piezas: [{nombre, pos, poly, enganchable}], controles: [Vector2], meta: Vector2,
#   caida_x, caida_ancho, camino: [Vector2] (techos principales, para los tests),
#   salidas_descanso: [Vector2] (borde de cada descanso, para los tests)
static func generar(semilla: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var m := {"piezas": [], "controles": [], "camino": [], "salidas_descanso": []}
	var x := INICIO_FIN
	var desde_descanso := 0
	var recien_descanso := true  # el suelo de salida cuenta como descanso
	m.salidas_descanso.append(Vector2(INICIO_FIN, SUELO_Y - 20.0))
	while x < LARGO:
		if desde_descanso >= 3 and x < LARGO - 1200.0 and (desde_descanso >= 4 or rng.randf() < 0.5):  # al final, tras un descanso no quedaría techo
			var ancho := rng.randf_range(220.0, 300.0)
			var centro := x + rng.randf_range(220.0, 280.0)
			_pieza(m, "Descanso", Vector2(centro, SUELO_Y), _caja(ancho, 40.0), false)
			m.controles.append(Vector2(centro, SUELO_Y - 80.0))
			m.salidas_descanso.append(Vector2(centro + ancho / 2.0, SUELO_Y - 20.0))
			x = centro + ancho / 2.0
			desde_descanso = 0
			recien_descanso = true
			continue
		var pos: Vector2
		if recien_descanso:  # a tiro desde el suelo: poco lejos y no muy alto
			pos = Vector2(x + rng.randf_range(100.0, 200.0), rng.randf_range(330.0, 370.0))
		else:
			pos = Vector2(x + rng.randf_range(520.0, 640.0), rng.randf_range(250.0, 380.0))
		var embudo := not recien_descanso and desde_descanso >= 1 and rng.randf() < 0.2
		if embudo:
			pos.y = rng.randf_range(390.0, 410.0)
		_techo(m, rng, pos, recien_descanso)
		m.camino.append(pos)
		if embudo:  # pilar desde abajo: deja un hueco estrecho bajo el techo
			var arriba := pos.y + rng.randf_range(150.0, 180.0)
			_pieza(m, "Pilar", Vector2(pos.x, (arriba + 1200.0) / 2.0), _irregular_caja(rng, 140.0, 1200.0 - arriba), false)
		elif rng.randf() < 0.25:  # bloque flotante para chocarse a mitad de vuelo
			var r := rng.randf_range(35.0, 50.0)
			_pieza(m, "Bloque", pos + Vector2(rng.randf_range(260.0, 320.0), rng.randf_range(130.0, 200.0)), _poligono(rng, r, rng.randi_range(5, 7)), false)
		if rng.randf() < 0.15:  # atajo alto: más difícil de alcanzar, pero ahorra un columpio
			_pieza(m, "Atajo", Vector2(pos.x + rng.randf_range(250.0, 330.0), rng.randf_range(60.0, 110.0)), _caja(rng.randf_range(120.0, 170.0), 40.0), true)
		x = pos.x
		desde_descanso += 1
		recien_descanso = false
	var suelo_meta := Vector2(x + 600.0, 720.0)
	_pieza(m, "SueloMeta", suelo_meta, _caja(700.0, 80.0), false)
	m.meta = suelo_meta + Vector2(150.0, -120.0)
	m.caida_x = m.meta.x / 2.0  # de x=-2000 a 2000 más allá de la meta
	m.caida_ancho = m.meta.x + 4000.0
	return m


# Un techo del camino con una forma al azar. Recién salido de un descanso, sin formas
# raras de las que sea difícil engancharse desde el suelo.
static func _techo(m: Dictionary, rng: RandomNumberGenerator, pos: Vector2, sencillo: bool) -> void:
	var ancho := rng.randf_range(200.0, 320.0)
	var tipo := 0 if sencillo else rng.randi_range(0, 4)
	match tipo:
		0:
			_pieza(m, "Techo", pos, _caja(ancho, 40.0), true)
		1:  # inclinado
			_pieza(m, "Techo", pos, _girar(_caja(ancho, 40.0), rng.randf_range(0.15, 0.35) * (1 if rng.randf() < 0.5 else -1)), true)
		2:  # trapecio
			var d := rng.randf_range(25.0, 60.0)
			_pieza(m, "Techo", pos, PackedVector2Array([Vector2(-ancho / 2, -20), Vector2(ancho / 2, -20), Vector2(ancho / 2 - d, 25), Vector2(-ancho / 2 + d, 25)]), true)
		3:  # triángulo con la punta hacia abajo
			_pieza(m, "Techo", pos, PackedVector2Array([Vector2(-ancho / 2, -25), Vector2(ancho / 2, -25), Vector2(rng.randf_range(-ancho / 4, ancho / 4), 45)]), true)
		4:  # roto: dos trozos torcidos con un hueco en medio
			var hueco := rng.randf_range(60.0, 90.0)
			var medio := (ancho - hueco) / 2.0
			var lado := (medio + hueco) / 2.0
			_pieza(m, "Techo", pos - Vector2(lado, 0), _girar(_caja(medio, 40.0), rng.randf_range(0.1, 0.25)), true)
			_pieza(m, "Techo", pos + Vector2(lado, rng.randf_range(-15.0, 15.0)), _girar(_caja(medio, 40.0), -rng.randf_range(0.1, 0.25)), true)


static func _pieza(m: Dictionary, tipo: String, pos: Vector2, poly: PackedVector2Array, enganchable: bool) -> void:
	m.piezas.append({"nombre": "%s%d" % [tipo, m.piezas.size()], "pos": pos, "poly": poly, "enganchable": enganchable})


static func _caja(ancho: float, alto: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-ancho / 2, -alto / 2), Vector2(ancho / 2, -alto / 2), Vector2(ancho / 2, alto / 2), Vector2(-ancho / 2, alto / 2)])


static func _irregular_caja(rng: RandomNumberGenerator, ancho: float, alto: float) -> PackedVector2Array:
	var c := _caja(ancho, alto)
	for i in c.size():
		c[i].x += rng.randf_range(-15.0, 15.0)
	return c


static func _girar(poly: PackedVector2Array, angulo: float) -> PackedVector2Array:
	var r := PackedVector2Array()
	for p in poly:
		r.append(p.rotated(angulo))
	return r


static func _poligono(rng: RandomNumberGenerator, radio: float, lados: int) -> PackedVector2Array:
	var r := PackedVector2Array()
	for i in lados:
		r.append(Vector2.from_angle(TAU * i / lados + rng.randf_range(-0.2, 0.2)) * radio * rng.randf_range(0.8, 1.15))
	return r
