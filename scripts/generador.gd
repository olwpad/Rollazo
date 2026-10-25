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
const PESOS_FORMA := {"horizontal": 30, "bajada": 25, "hibrido": 20, "montaña": 15, "torre": 10}  # en %
const INICIO_FIN := 650.0  # donde acaba el suelo de salida (caben 4 mocos a 90 px)
# Torre. Con estas medidas dos salientes seguidos quedan a <= 372 px (el papel llega a 420)
const TORRE_ALTO := 2400.0  # lo que sube el pozo desde el suelo
const POZO_ANCHO := 440.0  # hueco entre las dos paredes
const PARED_ANCHO := 60.0
const SALIENTE_ANCHO := Vector2(140.0, 170.0)  # (mín, máx)
const SALIENTE_SUBIDA := Vector2(180.0, 220.0)  # de un saliente al siguiente, en el otro lado
const DESCANSO_TORRE_ANCHO := 180.0
# Bajada. Se sale BAJADA_ALTO px más arriba que en horizontal y se acaba a la altura de siempre
const BAJADA_ALTO := 1600.0
const ESCALON_X := Vector2(500.0, 600.0)  # de un techo al siguiente (mín, máx)
const ESCALON_Y := Vector2(110.0, 160.0)  # lo que baja cada techo; poco, para no estamparse
const SUELO_BAJO_TECHO := Vector2(300.0, 340.0)  # de la parte de arriba de un suelo al techo a tiro (como en horizontal)
const SIERRA_BAJO_TECHO := 260.0  # el hueco va en la parte baja del arco, como los aros
const MONTANA_ALTO := 1200.0  # lo que sube la torre de la montaña y luego baja la bajada
const EMPALME_ANCHO := 250.0  # el descanso entre dos tramos


# Devuelve un Dictionary con:
#   piezas: [{nombre, pos, poly, enganchable}], controles: [Vector2], meta: Vector2,
#   forma, inicio, limites: Rect2, meta_tam, caida_y, caida_x, caida_ancho, camino: [Vector2] (techos principales, para los tests),
#   salidas_descanso: [Vector2] (borde de cada descanso, para los tests),
#   sierras: [{pos, riel: Vector2 (ZERO = quieta), fase, color}]
static func generar(semilla: int, forma := "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	if forma == "":
		forma = forma_de(semilla)
	var m := {"piezas": [], "controles": [], "camino": [], "salidas_descanso": [], "burbujas": []}
	m.forma = forma if forma in FORMAS else "horizontal"
	m.huecos_sierra = []
	var tramos := _tramos(m.forma, rng)
	var arriba: float = tramos[0][1] if tramos[0][0] == "bajada" else 0.0
	m.inicio = Vector2(200, 640 - arriba)
	m.salidas_descanso.append(Vector2(INICIO_FIN, SUELO_Y - 20.0 - arriba))
	if arriba > 0.0:
		_pieza(m, "SueloSalida", m.inicio + Vector2(100, 80), _caja(700.0, 80.0), false)  # como el SueloInicio de la escena
	var desde := Vector2(INICIO_FIN, SUELO_Y - arriba)
	var fin: Vector2
	for i in tramos.size():
		var tipo: String = tramos[i][0]
		var antes: int = m.camino.size()
		if tipo == "torre":
			fin = _tramo_torre(m, rng, desde, tramos[i][1])
		elif tipo == "bajada":
			fin = _tramo_bajada(m, rng, desde, tramos[i][1])
		else:
			fin = _tramo_horizontal(m, rng, desde, tramos[i][1])
		if tipo != "horizontal":  # el horizontal ya las pone
			_burbujas_vuelo(m, rng, antes)
		if i < tramos.size() - 1:
			desde = _empalme(m, tipo, fin)
		_quitar_estorbos(m)  # en cada tramo: un atajo tras su último techo se metería en el siguiente
	var ultimo: String = tramos.back()[0]
	# En horizontal el borde queda a 100 px del último techo; en la torre se sale andando del último descanso
	var suelo_meta := fin + Vector2(350.0 if ultimo == "torre" else 450.0, 30.0)
	_pieza(m, "SueloMeta", suelo_meta, _caja(700.0, 80.0), false)
	m.meta = suelo_meta + Vector2(150.0, -120.0)
	# Tras un techo también vale la caja alta: lo único a esa x es el suelo de meta
	m.meta_tam = Vector2(400, 300) if ultimo == "torre" else Vector2(220, 1600)
	m.caida_x = m.meta.x / 2.0  # de x=-2000 a 2000 más allá de la meta
	m.caida_ancho = m.meta.x + 4000.0
	m.limites = _limites(m)
	m.caida_y = maxf(1300.0, m.limites.end.y)
	if not m.forma in ["horizontal", "torre"]:  # caida_y es el centro de una franja de 200 px: que su borde de arriba quede bajo todo
		m.caida_y = maxf(m.caida_y, m.limites.end.y + 150.0)
	m.aros = _aros(semilla, m)
	m.sierras = _sierras(semilla, m)
	return m


# La forma que toca a esta semilla. Con su propio azar: añadir o quitar formas no cambia el interior de cada mapa.
static func forma_de(semilla: int) -> String:
	var elige := RandomNumberGenerator.new()
	elige.seed = hash(Vector2i(semilla, 3))
	return PESOS_FORMA.keys()[elige.rand_weighted(PackedFloat32Array(PESOS_FORMA.values()))]


# Los tramos de cada forma, con su medida (largo en x para el horizontal, altura para torre y bajada).
static func _tramos(forma: String, rng: RandomNumberGenerator) -> Array:
	match forma:
		"torre":
			return [["torre", TORRE_ALTO]]
		"bajada":
			return [["bajada", BAJADA_ALTO]]
		"montaña":  # se sube por un lado del muro y se baja por el otro
			return [["torre", MONTANA_ALTO], ["bajada", MONTANA_ALTO]]
		"hibrido":
			var n := rng.randi_range(2, 3)
			var tipos := []
			for i in n:
				tipos.append(["horizontal", "torre", "bajada"][rng.randi_range(0, 2)])
			if tipos.count("horizontal") == n:
				tipos[rng.randi_range(0, n - 1)] = ["torre", "bajada"][rng.randi_range(0, 1)]
			# Cada tramo 1/n de lo normal: el total queda como un mapa de una forma, no n veces más largo
			var medida := {"horizontal": (LARGO - INICIO_FIN) / n, "torre": TORRE_ALTO / n, "bajada": BAJADA_ALTO / n}
			return tipos.map(func(t: String) -> Array: return [t, medida[t]])
	return [["horizontal", LARGO - INICIO_FIN]]


# Une un tramo con el siguiente y devuelve el borde desde el que empieza. La torre ya acaba
# en un descanso: se empieza desde dentro de su pared derecha, así el primer techo queda a
# <= 680 px del último saliente. Tras un techo va un descanso con control donde iría el suelo de meta.
static func _empalme(m: Dictionary, tipo: String, fin: Vector2) -> Vector2:
	if tipo == "torre":
		return fin - Vector2(PARED_ANCHO, 0.0)
	var centro := Vector2(fin.x + 100.0 + EMPALME_ANCHO / 2.0, fin.y)
	_pieza(m, "Descanso", centro, _caja(EMPALME_ANCHO, 40.0), false)
	m.controles.append(centro + Vector2(0, -80.0))
	m.salidas_descanso.append(Vector2(centro.x + EMPALME_ANCHO / 2.0, fin.y - 20.0))
	return Vector2(centro.x + EMPALME_ANCHO / 2.0, fin.y)


# Burbujas de poder en el vuelo entre dos techos seguidos, desde el techo `desde_i` del camino,
# para los tramos que no las ponen solos. Por encima del hueco de la sierra, nunca dentro de una pieza.
static func _burbujas_vuelo(m: Dictionary, rng: RandomNumberGenerator, desde_i: int) -> void:
	for i in range(maxi(desde_i, 1), m.camino.size()):
		var a: Vector2 = m.camino[i - 1]
		var b: Vector2 = m.camino[i]
		var pos := Vector2((a.x + b.x) / 2.0, maxf(a.y, b.y) + 100.0)
		var libre: bool = m.piezas.all(func(p: Dictionary) -> bool: return _distancia(pos, p) > 60.0) \
				and m.huecos_sierra.all(func(h: Vector2) -> bool: return pos.distance_to(h) > 150.0) \
				and m.burbujas.all(func(q: Dictionary) -> bool: return pos.distance_to(q.pos) > 300.0)
		if rng.randf() < 0.7 and libre:
			m.burbujas.append({"pos": pos, "tipo": _tipo_burbuja(m, rng)})


# Un poder distinto del de la burbuja anterior del camino: si no, una torre da siempre el mismo.
static func _tipo_burbuja(m: Dictionary, rng: RandomNumberGenerator) -> String:
	var tipos: Array = Poderes.TIPOS.duplicate()
	if not m.burbujas.is_empty():
		tipos.erase(m.burbujas.back().tipo)
	return tipos[rng.randi_range(0, tipos.size() - 1)]


# El bucle de techos y descansos, desde el borde `desde` del suelo anterior y a lo largo de
# `largo` px en x. Las alturas van respecto a ese suelo (en un mapa horizontal, SUELO_Y).
# Devuelve el borde donde acaba.
static func _tramo_horizontal(m: Dictionary, rng: RandomNumberGenerator, desde: Vector2, largo: float) -> Vector2:
	var dy := desde.y - SUELO_Y
	var x := desde.x
	var hasta := desde.x + largo
	var desde_descanso := 0
	var desde_burbuja := 0  # techos sin burbuja: a los 3, sale una seguro
	var recien_descanso := true  # el suelo de salida cuenta como descanso
	while x < hasta:
		if desde_descanso >= 3 and x < hasta - 1200.0 and (desde_descanso >= 4 or rng.randf() < 0.5):  # al final, tras un descanso no quedaría techo
			var ancho := rng.randf_range(220.0, 300.0)
			var centro := x + rng.randf_range(220.0, 280.0)
			_pieza(m, "Descanso", Vector2(centro, desde.y), _caja(ancho, 40.0), false)
			m.controles.append(Vector2(centro, desde.y - 80.0))
			m.salidas_descanso.append(Vector2(centro + ancho / 2.0, desde.y - 20.0))
			x = centro + ancho / 2.0
			desde_descanso = 0
			recien_descanso = true
			continue
		var pos: Vector2
		if recien_descanso:  # a tiro desde el suelo: poco lejos y no muy alto
			pos = Vector2(x + rng.randf_range(100.0, 200.0), dy + rng.randf_range(330.0, 370.0))
		else:
			pos = Vector2(x + rng.randf_range(520.0, 640.0), dy + rng.randf_range(250.0, 380.0))
		# Embudos: nunca antes del primer control (el bot se estrellaba ahí sin haber guardado nada)
		var embudo: bool = not recien_descanso and desde_descanso >= 1 and m.controles.size() > 0 and rng.randf() < 0.12
		if embudo:
			pos.y = dy + rng.randf_range(390.0, 410.0)
		_techo(m, rng, pos, recien_descanso, embudo)
		m.camino.append(pos)
		if embudo:  # pilar desde abajo: deja un hueco estrecho bajo el techo
			var arriba := pos.y + rng.randf_range(230.0, 260.0)  # pasa un columpio normal; más cerrado se estrellaba
			_pieza(m, "Pilar", Vector2(pos.x, (arriba + 1200.0 + dy) / 2.0), _irregular_caja(rng, 140.0, 1200.0 + dy - arriba), false)
		elif rng.randf() < 0.25:  # bloque flotante para chocarse a mitad de vuelo
			var r := rng.randf_range(35.0, 50.0)
			_pieza(m, "Bloque", pos + Vector2(rng.randf_range(260.0, 320.0), rng.randf_range(130.0, 200.0)), _poligono(rng, r, rng.randi_range(5, 7)), false)
		desde_burbuja += 1
		if not recien_descanso and (rng.randf() < 0.35 or desde_burbuja >= 3):  # burbuja de poder donde pasa el columpio
			desde_burbuja = 0
			m.burbujas.append({"pos": pos + Vector2(rng.randf_range(-120.0, 120.0), rng.randf_range(170.0, 220.0)),
					"tipo": _tipo_burbuja(m, rng)})
		if rng.randf() < 0.15:  # atajo alto: más difícil de alcanzar, pero ahorra un columpio
			_pieza(m, "Atajo", Vector2(pos.x + rng.randf_range(250.0, 330.0), dy + rng.randf_range(60.0, 110.0)), _caja(rng.randf_range(120.0, 170.0), 40.0), true)
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
# del saliente siguiente, encima del anterior de ese lado. Se entra por abajo a la izquierda y
# se sale por el último descanso, arriba a la derecha. Devuelve el borde de ese descanso.
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
			# Apoyado sobre el saliente de ese lado de debajo: si quedara hueco entre los dos, el bot (y un moco) se encajaba ahí
			_descanso_torre(m, izq, der, lado, m.camino[-2].y - 40.0, DESCANSO_TORRE_ANCHO)
			desde_descanso = 0
	# El último tapa la pared derecha para salir andando hacia la meta
	var centro_y: float = m.camino[-2].y - 40.0  # igual, sobre el último de la derecha; se sube desde el último saliente
	_descanso_torre(m, izq, der + PARED_ANCHO, 1, centro_y, DESCANSO_TORRE_ANCHO + PARED_ANCHO)
	m.salidas_descanso[-1] = Vector2(der + PARED_ANCHO, centro_y - 20.0)  # de este se sale andando por la derecha
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
		var libre: bool = m.piezas.all(func(p: Dictionary) -> bool: return pos.distance_to(p.pos) > 200.0 and _distancia(pos, p) > 60.0) \
				and m.burbujas.all(func(q: Dictionary) -> bool: return pos.distance_to(q.pos) > 130.0) \
				and m.huecos_sierra.all(func(h: Vector2) -> bool: return pos.distance_to(h) > 200.0)
		# Lejos de salida y meta en cualquier forma (en horizontal, x > INICIO_FIN + 400 y x < meta - 300)
		if libre and m.limites.has_point(pos) and pos.distance_to(m.inicio) > INICIO_FIN + 250.0 and pos.distance_to(m.meta) > 350.0:
			huecos.append(pos)
	var aros := []
	for k in mini(2, huecos.size()):
		var pos: Vector2 = huecos.pop_at(rng.randi_range(0, huecos.size() - 1))
		aros.append({"pos": pos, "mov": "quieto" if rng.randf() < 0.5 else "sube"})
	return aros


# Sierras: hasta 3 en los huecos del arco de las bajadas y 1 más entre dos techos de un tramo
# horizontal; en la torre no, que se trepa pegado a las paredes. Con su propio azar, como los aros.
static func _sierras(semilla: int, m: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 11))
	# Que se vea venir y no te devuelva lejos: nada cerca de controles, salida ni meta
	var libre := func(pos: Vector2) -> bool:
		return m.limites.has_point(pos) and pos.distance_to(m.inicio) > 400.0 and pos.distance_to(m.meta) > 350.0 \
				and m.controles.all(func(c: Vector2) -> bool: return pos.distance_to(c) > 250.0) \
				and m.piezas.all(func(p: Dictionary) -> bool: return _distancia(pos, p) > 60.0) \
				and m.burbujas.all(func(b: Dictionary) -> bool: return pos.distance_to(b.pos) > 100.0) \
				and m.aros.all(func(a: Dictionary) -> bool: return pos.distance_to(a.pos) > 200.0)
	var bajada: Array = m.huecos_sierra.filter(libre)
	var llano := []
	for i in range(1, m.camino.size()):
		var a: Vector2 = m.camino[i - 1]
		var b: Vector2 = m.camino[i]
		var pos := Vector2((a.x + b.x) / 2.0, maxf(a.y, b.y) + SIERRA_BAJO_TECHO)
		# b.x - a.x > 300: un paso de torre va de pared a pared, casi en vertical
		if b.x - a.x > 300.0 and libre.call(pos) and m.huecos_sierra.all(func(h: Vector2) -> bool: return pos.distance_to(h) > 200.0):
			llano.append(pos)
	var sitios := []
	for k in mini(3, bajada.size()):
		sitios.append(bajada.pop_at(rng.randi_range(0, bajada.size() - 1)))
	if not llano.is_empty():
		sitios.append(llano[rng.randi_range(0, llano.size() - 1)])
	var sierras := []
	for pos: Vector2 in sitios:
		var riel := Vector2.ZERO
		if rng.randf() < 0.5:  # en riel: de lado a lo largo del hueco, o subiendo hacia el techo
			var lado := rng.randf_range(160.0, 220.0) * (1.0 if rng.randf() < 0.5 else -1.0)
			riel = Vector2(lado, 0.0) if rng.randf() < 0.5 else Vector2(0.0, -rng.randf_range(100.0, 150.0))
			if not (libre.call(pos + riel) and libre.call(pos + riel / 2.0)):
				riel = Vector2.ZERO
		sierras.append({"pos": pos, "riel": riel, "fase": rng.randf(), "color": rng.randi_range(0, Sierra.COLORES.size() - 1)})
	return sierras


# Distancia de `pos` al borde de la pieza `p`; 0 si está dentro (una pared es larga: su centro no basta).
static func _distancia(pos: Vector2, p: Dictionary) -> float:
	var local: Vector2 = pos - p.pos
	if Geometry2D.is_point_in_polygon(local, p.poly):
		return 0.0
	var d := INF
	for i in p.poly.size():
		d = minf(d, local.distance_to(Geometry2D.get_closest_point_to_segment(local, p.poly[i], p.poly[(i + 1) % p.poly.size()])))
	return d


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
