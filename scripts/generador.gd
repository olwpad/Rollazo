# Genera un recorrido al azar a partir de una semilla. Con la misma semilla sale siempre
# el mismo mapa (como new Random(semilla) en Java), así los 4 PCs construyen lo mismo
# y solo hace falta mandar un número por la red.
#
# Reglas para que siempre se pueda pasar: los techos del camino van a 520-640 px uno del
# otro y a una altura que el papel alcanza; tras cada descanso, el techo siguiente queda a
# tiro desde el suelo. Lo demás (atajos, bloques, embudos) es extra.
class_name Generador
extends RefCounted

const NOMBRE := "LA AZOTEA"  # el nombre que sale en las postales
const LARGO := 7600.0  # a partir de aquí se pone la meta
const SUELO_Y := 690.0  # centro de los descansos (la parte de arriba queda en y=670)
const INICIO_FIN := 650.0  # donde acaba el suelo de salida (caben 4 mocos a 90 px)


# Devuelve un Dictionary con:
#   piezas: [{nombre, pos, poly, enganchable}], controles: [Vector2], meta: Vector2,
#   caida_x, caida_ancho, camino: [Vector2] (techos principales, para los tests),
#   salidas_descanso: [Vector2] (borde de cada descanso, para los tests)
static func generar(semilla: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var m := {"piezas": [], "controles": [], "camino": [], "salidas_descanso": [], "burbujas": []}
	var x := INICIO_FIN
	var desde_descanso := 0
	var desde_burbuja := 0  # techos sin burbuja: a los 3, sale una seguro
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
		# Embudos: nunca antes del primer control (el bot se estrellaba ahí sin haber guardado nada)
		var embudo: bool = not recien_descanso and desde_descanso >= 1 and m.controles.size() > 0 and rng.randf() < 0.12
		if embudo:
			pos.y = rng.randf_range(390.0, 410.0)
		_techo(m, rng, pos, recien_descanso, embudo)
		m.camino.append(pos)
		if embudo:  # pilar desde abajo: deja un hueco estrecho bajo el techo
			var arriba := pos.y + rng.randf_range(230.0, 260.0)  # pasa un columpio normal; más cerrado se estrellaba
			_pieza(m, "Pilar", Vector2(pos.x, (arriba + 1200.0) / 2.0), _irregular_caja(rng, 140.0, 1200.0 - arriba), false)
		elif rng.randf() < 0.25:  # bloque flotante para chocarse a mitad de vuelo
			var r := rng.randf_range(35.0, 50.0)
			_pieza(m, "Bloque", pos + Vector2(rng.randf_range(260.0, 320.0), rng.randf_range(130.0, 200.0)), _poligono(rng, r, rng.randi_range(5, 7)), false)
		desde_burbuja += 1
		if not recien_descanso and (rng.randf() < 0.35 or desde_burbuja >= 3):  # burbuja de poder donde pasa el columpio
			desde_burbuja = 0
			m.burbujas.append({"pos": pos + Vector2(rng.randf_range(-120.0, 120.0), rng.randf_range(170.0, 220.0)),
					"tipo": Poderes.TIPOS[rng.randi_range(0, Poderes.TIPOS.size() - 1)]})
		if rng.randf() < 0.15:  # atajo alto: más difícil de alcanzar, pero ahorra un columpio
			_pieza(m, "Atajo", Vector2(pos.x + rng.randf_range(250.0, 330.0), rng.randf_range(60.0, 110.0)), _caja(rng.randf_range(120.0, 170.0), 40.0), true)
		x = pos.x
		desde_descanso += 1
		recien_descanso = false
	_quitar_estorbos(m)
	var suelo_meta := Vector2(x + 450.0, 720.0)  # el borde queda a 100 px del último techo
	_pieza(m, "SueloMeta", suelo_meta, _caja(700.0, 80.0), false)
	m.meta = suelo_meta + Vector2(150.0, -120.0)
	m.caida_x = m.meta.x / 2.0  # de x=-2000 a 2000 más allá de la meta
	m.caida_ancho = m.meta.x + 4000.0
	m.aros = _aros(semilla, m)
	return m


# Aros de fuego en el hueco entre dos techos, por donde pasa el vuelo. Van con su propio
# azar: así poner o quitar aros no cambia el resto del mapa. Solo los usan algunos temas.
static func _aros(semilla: int, m: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 7))
	var huecos := []
	var camino: Array = m.camino
	for i in range(1, camino.size()):
		var a: Vector2 = camino[i - 1]
		var b: Vector2 = camino[i]
		var pos := Vector2((a.x + b.x) / 2.0, maxf(a.y, b.y) + 200.0)
		var libre: bool = m.piezas.all(func(p: Dictionary) -> bool: return pos.distance_to(p.pos) > 160.0) 				and m.burbujas.all(func(q: Dictionary) -> bool: return pos.distance_to(q.pos) > 130.0)
		if libre and pos.x > INICIO_FIN + 400.0 and pos.x < m.meta.x - 300.0:
			huecos.append(pos)
	var aros := []
	for k in mini(3, huecos.size()):
		var pos: Vector2 = huecos.pop_at(rng.randi_range(0, huecos.size() - 1))
		aros.append({"pos": pos, "mov": "quieto" if rng.randf() < 0.5 else "sube"})
	return aros


# Un techo del camino con una forma al azar. Recién salido de un descanso, sin formas
# raras de las que sea difícil engancharse desde el suelo.
static func _techo(m: Dictionary, rng: RandomNumberGenerator, pos: Vector2, sencillo: bool, sobre_pilar := false) -> void:
	var ancho := rng.randf_range(200.0, 320.0)
	var tipo := 0 if sencillo else rng.randi_range(0, 4)
	if sobre_pilar:  # sobre un embudo, ni triángulo ni roto: dejarían el hueco justo encima del pilar
		tipo = [0, 2][rng.randi_range(0, 1)]
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


# Quita lo que el bot probador encontró injusto: bloques justo encima de un descanso (te
# encajan) y atajos en el último techo (te lanzan más allá de la meta).
static func _quitar_estorbos(m: Dictionary) -> void:
	var descansos: Array = m.piezas.filter(func(p: Dictionary) -> bool: return p.nombre.begins_with("Descanso"))
	var ultimo: float = m.camino.back().x
	m.piezas = m.piezas.filter(func(p: Dictionary) -> bool:
		if p.nombre.begins_with("Atajo"):
			return p.pos.x < ultimo
		if p.nombre.begins_with("Bloque"):
			return not descansos.any(func(d: Dictionary) -> bool: return absf(p.pos.x - d.pos.x) < 220.0 and d.pos.y - p.pos.y < 250.0)
		return true)


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
