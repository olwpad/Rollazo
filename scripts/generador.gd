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
const FORMAS := ["horizontal", "torre", "bajada", "montaña", "hibrido"]
const INICIO_FIN := 650.0  # donde acaba el suelo de salida (caben 4 mocos a 90 px)
# Torre. Con estas medidas dos salientes seguidos quedan a <= 372 px (el papel llega a 420)
const TORRE_ALTO := 2400.0  # lo que sube el pozo desde el suelo
const POZO_ANCHO := 440.0  # hueco entre las dos paredes
const PARED_ANCHO := 60.0
const SALIENTE_ANCHO := Vector2(140.0, 170.0)  # (mín, máx)
const SALIENTE_SUBIDA := Vector2(180.0, 220.0)  # de un saliente al siguiente, en el otro lado
const DESCANSO_TORRE_ANCHO := 180.0
const DESCANSO_BAJO_SALIENTE := 280.0  # el descanso va debajo del saliente siguiente, como el suelo bajo un techo
# Bajada. Se sale BAJADA_ALTO px más arriba que en horizontal y se acaba a la altura de siempre
const BAJADA_ALTO := 1600.0
const ESCALON_X := Vector2(500.0, 600.0)  # de un techo al siguiente (mín, máx)
const ESCALON_Y := Vector2(110.0, 160.0)  # lo que baja cada techo; poco, para no estamparse
const SUELO_BAJO_TECHO := Vector2(300.0, 340.0)  # de la parte de arriba de un suelo al techo a tiro (como en horizontal)
const SIERRA_BAJO_TECHO := 260.0  # el hueco va en la parte baja del arco, como los aros


# Devuelve un Dictionary con:
#   piezas: [{nombre, pos, poly, enganchable}], controles: [Vector2], meta: Vector2,
#   forma, inicio, limites: Rect2, meta_tam, caida_y, caida_x, caida_ancho, camino: [Vector2] (techos principales, para los tests),
#   salidas_descanso: [Vector2] (borde de cada descanso, para los tests)
static func generar(semilla: int, forma := "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var m := {"piezas": [], "controles": [], "camino": [], "salidas_descanso": [], "burbujas": []}
	m.forma = forma if forma in ["torre", "bajada"] else "horizontal"  # shortcut: montaña e híbrido aún caen en horizontal
	m.huecos_sierra = []
	var arriba := BAJADA_ALTO if m.forma == "bajada" else 0.0
	m.inicio = Vector2(200, 640 - arriba)
	m.salidas_descanso.append(Vector2(INICIO_FIN, SUELO_Y - 20.0 - arriba))
	var fin: Vector2
	if m.forma == "torre":
		fin = _tramo_torre(m, rng, Vector2(INICIO_FIN, SUELO_Y), TORRE_ALTO)
	elif m.forma == "bajada":
		_pieza(m, "SueloSalida", m.inicio + Vector2(100, 80), _caja(700.0, 80.0), false)  # como el SueloInicio de la escena
		fin = _tramo_bajada(m, rng, Vector2(INICIO_FIN, SUELO_Y - arriba), BAJADA_ALTO)
	else:
		fin = _tramo_horizontal(m, rng, Vector2(INICIO_FIN, SUELO_Y), LARGO - INICIO_FIN)
	_quitar_estorbos(m)
	# En horizontal el borde queda a 100 px del último techo; en la torre se sale andando del último descanso
	var suelo_meta := fin + Vector2(350.0 if m.forma == "torre" else 450.0, 30.0)
	_pieza(m, "SueloMeta", suelo_meta, _caja(700.0, 80.0), false)
	m.meta = suelo_meta + Vector2(150.0, -120.0)
	# En la bajada también vale la caja alta: lo único a esa x es el suelo de meta, tras el último techo
	m.meta_tam = Vector2(400, 300) if m.forma == "torre" else Vector2(220, 1600)
	m.caida_x = m.meta.x / 2.0  # de x=-2000 a 2000 más allá de la meta
	m.caida_ancho = m.meta.x + 4000.0
	m.limites = _limites(m)
	m.caida_y = maxf(1300.0, m.limites.end.y)
	if m.forma == "bajada":  # caida_y es el centro de una franja de 200 px: que su borde de arriba quede bajo todo
		m.caida_y = maxf(m.caida_y, m.limites.end.y + 150.0)
	m.aros = _aros(semilla, m)
	return m


# El bucle de techos y descansos, desde el borde `desde` del suelo anterior y a lo largo de
# `largo` px en x. Devuelve el borde donde acaba.
static func _tramo_horizontal(m: Dictionary, rng: RandomNumberGenerator, desde: Vector2, largo: float) -> Vector2:
	var x := desde.x
	var hasta := desde.x + largo
	var desde_descanso := 0
	var desde_burbuja := 0  # techos sin burbuja: a los 3, sale una seguro
	var recien_descanso := true  # el suelo de salida cuenta como descanso
	while x < hasta:
		if desde_descanso >= 3 and x < hasta - 1200.0 and (desde_descanso >= 4 or rng.randf() < 0.5):  # al final, tras un descanso no quedaría techo
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
	return Vector2(x, desde.y)


# Techos en escalera, cada uno más abajo y más a la derecha, desde el borde `desde` del suelo
# anterior hasta bajar `largo` px. Cada 3-4 techos un descanso, como en horizontal pero bajo
# el techo siguiente. El truco es frenar. Apunta en m.huecos_sierra los huecos del arco
# entre techos. Devuelve el borde (a la altura de un suelo) donde acaba.
static func _tramo_bajada(m: Dictionary, rng: RandomNumberGenerator, desde: Vector2, largo: float) -> Vector2:
	var hasta := desde.y + largo
	# El primero a tiro desde el suelo de salida
	var pos := Vector2(desde.x + rng.randf_range(100.0, 200.0), desde.y - 20.0 - rng.randf_range(SUELO_BAJO_TECHO.x, SUELO_BAJO_TECHO.y))
	var desde_descanso := 0
	var sencillo := true
	while true:
		_techo(m, rng, pos, sencillo)
		m.camino.append(pos)
		desde_descanso += 1
		var siguiente := pos + Vector2(rng.randf_range(ESCALON_X.x, ESCALON_X.y), rng.randf_range(ESCALON_Y.x, ESCALON_Y.y))
		if siguiente.y + SUELO_BAJO_TECHO.y > hasta:
			break
		sencillo = desde_descanso >= 3 and (desde_descanso >= 4 or rng.randf() < 0.5)
		if sencillo:  # descanso debajo del techo siguiente, que queda a tiro desde su borde
			var ancho := rng.randf_range(220.0, 300.0)
			var suelo := siguiente.y + 20.0 + rng.randf_range(SUELO_BAJO_TECHO.x, SUELO_BAJO_TECHO.y)
			var borde := siguiente.x - rng.randf_range(100.0, 200.0)
			_pieza(m, "Descanso", Vector2(borde - ancho / 2.0, suelo), _caja(ancho, 40.0), false)
			m.controles.append(Vector2(borde - ancho / 2.0, suelo - 80.0))
			m.salidas_descanso.append(Vector2(borde, suelo - 20.0))
			desde_descanso = 0
		else:
			m.huecos_sierra.append(Vector2((pos.x + siguiente.x) / 2.0, siguiente.y + SIERRA_BAJO_TECHO))
		pos = siguiente
	return Vector2(pos.x, pos.y + SUELO_BAJO_TECHO.y + 20.0)


# Un pozo entre dos paredes que sube `alto` px desde el borde `desde` del suelo anterior.
# Los salientes se alternan izquierda/derecha; cada 3-4, un descanso con control en el lado
# del saliente siguiente, justo debajo de él. Se entra por abajo a la izquierda y se sale
# por el último descanso, arriba a la derecha. Devuelve el borde de ese descanso.
static func _tramo_torre(m: Dictionary, rng: RandomNumberGenerator, desde: Vector2, alto: float) -> Vector2:
	var izq := desde.x + PARED_ANCHO
	var der := izq + POZO_ANCHO
	var tope := desde.y - alto
	_pieza(m, "SueloPozo", Vector2((desde.x + der + PARED_ANCHO) / 2.0, desde.y), _caja(der + PARED_ANCHO - desde.x, 40.0), false)
	var y := desde.y - 20.0 - rng.randf_range(300.0, 340.0)  # el primero, a tiro desde el suelo
	var lado := 0  # 0 = izquierda (al alcance desde el suelo de salida), 1 = derecha
	var desde_descanso := 0
	while true:
		var ancho := rng.randf_range(SALIENTE_ANCHO.x, SALIENTE_ANCHO.y)
		var pos := Vector2(izq + ancho / 2.0 if lado == 0 else der - ancho / 2.0, y)
		_pieza(m, "Techo", pos, _caja(ancho, 40.0), true)
		m.camino.append(pos)
		desde_descanso += 1
		lado = 1 - lado
		y -= rng.randf_range(SALIENTE_SUBIDA.x, SALIENTE_SUBIDA.y)
		if pos.y < tope and lado == 1:  # el último a la izquierda: el descanso final va a la derecha
			break
		# Con TORRE_ALTO 2400 caben siempre 2 descansos más el final (3 controles)
		if desde_descanso >= 3 and y > tope + 200.0 and (desde_descanso >= 4 or rng.randf() < 0.5):
			_descanso_torre(m, izq, der, lado, y + DESCANSO_BAJO_SALIENTE, DESCANSO_TORRE_ANCHO)
			desde_descanso = 0
	# El último tapa la pared derecha para salir andando hacia la meta
	var centro_y := y + DESCANSO_BAJO_SALIENTE
	_descanso_torre(m, izq, der + PARED_ANCHO, 1, centro_y, DESCANSO_TORRE_ANCHO + PARED_ANCHO)
	_pieza(m, "Pared", Vector2(desde.x + PARED_ANCHO / 2.0, (tope - 400.0 + desde.y - 260.0) / 2.0), _caja(PARED_ANCHO, desde.y - 260.0 - tope + 400.0), false)  # abajo deja la entrada
	_pieza(m, "Pared", Vector2(der + PARED_ANCHO / 2.0, (centro_y + 20.0 + desde.y) / 2.0), _caja(PARED_ANCHO, desde.y - centro_y - 20.0), false)
	return Vector2(der + PARED_ANCHO, centro_y)


# Un descanso pegado a la pared `lado` (de `izq` a `der`), con su control y su borde hacia el pozo.
static func _descanso_torre(m: Dictionary, izq: float, der: float, lado: int, centro_y: float, ancho: float) -> void:
	var centro := Vector2(izq + ancho / 2.0 if lado == 0 else der - ancho / 2.0, centro_y)
	_pieza(m, "Descanso", centro, _caja(ancho, 40.0), false)
	m.controles.append(centro + Vector2(0, -80.0))
	m.salidas_descanso.append(Vector2(izq + ancho if lado == 0 else der - ancho, centro_y - 20.0))


# La caja que lo contiene todo, con margen; por abajo menos, para que la caída siga en y=1300.
static func _limites(m: Dictionary) -> Rect2:
	var caja := Rect2(m.inicio, Vector2.ZERO).expand(m.meta)
	for p: Dictionary in m.piezas:
		for v: Vector2 in p.poly:
			caja = caja.expand(p.pos + v)
	for c: Vector2 in m.controles:
		caja = caja.expand(c)
	for b: Dictionary in m.burbujas:
		caja = caja.expand(b.pos)
	return caja.grow_individual(200.0, 200.0, 200.0, 100.0)


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
		var pos := Vector2((a.x + b.x) / 2.0, maxf(a.y, b.y) + 260.0)  # en la bajada del arco: o lo cruzas por el centro o vas por encima
		var libre: bool = m.piezas.all(func(p: Dictionary) -> bool: return pos.distance_to(p.pos) > 200.0) 				and m.burbujas.all(func(q: Dictionary) -> bool: return pos.distance_to(q.pos) > 130.0)
		if libre and pos.x > INICIO_FIN + 400.0 and pos.x < m.meta.x - 300.0:
			huecos.append(pos)
	var aros := []
	for k in mini(2, huecos.size()):
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
