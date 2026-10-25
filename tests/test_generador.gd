extends Caso


func test_misma_semilla_mismo_mapa() -> void:
	var a := Generador.generar(42, "horizontal")
	var b := Generador.generar(42, "horizontal")
	comprobar(var_to_str(a) == var_to_str(b), "los 4 PCs construyen lo mismo")
	comprobar(var_to_str(a) != var_to_str(Generador.generar(43, "horizontal")), "otra semilla, otro mapa")


func test_largo_con_controles_y_caida() -> void:
	for semilla in 20:
		var m := Generador.generar(semilla, "horizontal")
		comprobar(m.meta.x >= 7500.0, "largo (semilla %d, meta %.0f)" % [semilla, m.meta.x])
		comprobar(m.controles.size() >= 2, "puntos de control (semilla %d)" % semilla)
		comprobar(m.caida_x - m.caida_ancho / 2.0 < 0.0 and m.caida_x + m.caida_ancho / 2.0 > m.meta.x + 500.0, "la caída cubre todo (semilla %d)" % semilla)


func test_no_todo_son_rectangulos() -> void:
	var raros := 0
	for p in Generador.generar(7, "horizontal").piezas:
		var poly: PackedVector2Array = p.poly
		if poly.size() != 4 or not is_zero_approx(poly[0].y - poly[1].y):
			raros += 1
	comprobar(raros >= 4, "formas irregulares: %d" % raros)


# El camino principal siempre se puede recorrer: cada techo está al alcance del anterior,
# y desde cada descanso se alcanza el techo siguiente con el papel.
func test_siempre_alcanzable() -> void:
	for semilla in 50:
		var m := Generador.generar(semilla, "horizontal")
		var camino: Array = m.camino
		for i in range(1, camino.size()):
			var d: Vector2 = camino[i] - camino[i - 1]
			comprobar(d.x > 0.0 and d.x <= 680.0 and camino[i].y >= 240.0 and camino[i].y <= 420.0,
					"semilla %d: salto %d de %s a %s" % [semilla, i, camino[i - 1], camino[i]])
		for borde: Vector2 in m.salidas_descanso:
			var alcanza := camino.any(func(c: Vector2) -> bool: return c.x > borde.x and c.distance_to(borde) <= PapelRope.LARGO_MAX - 20.0)
			comprobar(alcanza, "semilla %d: desde el descanso en %s no se alcanza ningún techo" % [semilla, borde])


func _piezas(m: Dictionary, tipo: String) -> Array:
	return m.piezas.filter(func(p: Dictionary) -> bool: return p.nombre.begins_with(tipo))


func _alto(p: Dictionary) -> float:
	var arriba := INF
	for v: Vector2 in p.poly:
		arriba = minf(arriba, v.y)
	return p.pos.y + arriba


# El bot se estrellaba en los embudos: el pilar debe dejar pasar un columpio normal.
func test_embudos_pasables() -> void:
	for semilla in 60:
		var m := Generador.generar(semilla, "horizontal")
		for pilar in _piezas(m, "Pilar"):
			var techo: Vector2 = m.camino.reduce(func(a: Vector2, c: Vector2) -> Vector2: return c if absf(c.x - pilar.pos.x) < absf(a.x - pilar.pos.x) else a)
			comprobar(_alto(pilar) - techo.y >= 230.0, "semilla %d: hueco del embudo %.0f px" % [semilla, _alto(pilar) - techo.y])
			comprobar(m.controles.size() > 0 and pilar.pos.x > m.controles[0].x, "semilla %d: embudo antes del primer control" % semilla)


func test_sin_bloques_encima_de_descansos_ni_atajos_tras_el_ultimo_techo() -> void:
	for semilla in 60:
		var m := Generador.generar(semilla, "horizontal")
		for b in _piezas(m, "Bloque"):
			for d in _piezas(m, "Descanso"):
				var encima: bool = absf(b.pos.x - d.pos.x) < 220.0 and d.pos.y - b.pos.y < 250.0
				comprobar(not encima, "semilla %d: bloque en %s encima del descanso" % [semilla, b.pos])
		for a in _piezas(m, "Atajo"):
			comprobar(a.pos.x < m.camino.back().x, "semilla %d: atajo tras el último techo lanza más allá de la meta" % semilla)


func test_suelo_de_meta_cerca_del_ultimo_techo() -> void:
	for semilla in 60:
		var m := Generador.generar(semilla, "horizontal")
		var suelo: Dictionary = _piezas(m, "SueloMeta")[0]
		var borde: float = suelo.pos.x - 350.0
		comprobar(borde - m.camino.back().x <= 150.0, "semilla %d: hueco hasta el suelo de meta %.0f px" % [semilla, borde - m.camino.back().x])


func test_campos_nuevos_del_mapa() -> void:
	var m := Generador.generar(3, "horizontal")
	comprobar(m.forma == "horizontal", "forma")
	comprobar(m.inicio == Vector2(200, 640), "salida como hasta ahora")
	comprobar(m.caida_y >= 1200.0, "caída por debajo de todo")
	for p in m.piezas:
		comprobar(m.limites.grow(1.0).has_point(p.pos), "pieza %s dentro de los límites" % p.nombre)
	comprobar(m.limites.has_point(m.meta), "meta dentro")


func test_torre_sube_y_se_puede_escalar() -> void:
	for semilla in 40:
		var m := Generador.generar(semilla, "torre")
		comprobar(m.meta.y < m.inicio.y - 1500.0, "semilla %d: la meta queda muy arriba" % semilla)
		for i in range(1, m.camino.size()):
			var d: Vector2 = m.camino[i] - m.camino[i - 1]
			comprobar(d.length() <= PapelRope.LARGO_MAX - 40.0, "semilla %d: saliente %d a %.0f px" % [semilla, i, d.length()])
		for p in _piezas(m, "Pared"):
			comprobar(not p.enganchable, "las paredes no enganchan")
		comprobar(m.controles.size() >= 3, "semilla %d: controles a lo largo de la torre" % semilla)


func test_torre_mapa_completo() -> void:
	var m := Generador.generar(5, "torre")
	comprobar(m.forma == "torre", "forma")
	comprobar(_piezas(m, "SueloMeta").size() == 1 and _piezas(m, "Pared").size() == 2, "suelo de meta y dos paredes")
	for borde: Vector2 in m.salidas_descanso:
		var alcanza: bool = m.camino.any(func(c: Vector2) -> bool: return c.y < borde.y and c.distance_to(borde) <= PapelRope.LARGO_MAX - 20.0)
		comprobar(alcanza or borde == m.salidas_descanso.back(), "desde el descanso en %s se alcanza un saliente" % borde)
	for p in m.piezas:
		comprobar(m.limites.has_point(p.pos), "pieza %s dentro de los límites" % p.nombre)
	comprobar(m.limites.has_point(m.meta) and m.limites.has_point(m.inicio), "meta y salida dentro")
	comprobar(m.caida_y >= m.limites.end.y, "caída por debajo de todo")
	comprobar(m.meta_tam.y < 500.0, "la meta solo cubre el suelo de arriba")


func test_bajada_baja_y_la_caida_queda_debajo() -> void:
	for semilla in 40:
		var m := Generador.generar(semilla, "bajada")
		comprobar(m.meta.y > m.inicio.y + 800.0, "semilla %d: la meta queda abajo" % semilla)
		for i in range(1, m.camino.size()):
			var d: Vector2 = m.camino[i] - m.camino[i - 1]
			comprobar(d.x > 0.0 and d.y > 0.0 and d.x <= 680.0, "semilla %d: escalón %d %s" % [semilla, i, d])
		comprobar(m.caida_y > m.limites.end.y, "semilla %d: la franja que mata está bajo todo" % semilla)
		comprobar(m.huecos_sierra.size() >= 2, "sitio para sierras")


func test_bajada_mapa_completo() -> void:
	for semilla in 40:
		var m := Generador.generar(semilla, "bajada")
		comprobar(m.forma == "bajada", "forma")
		var salida: Array = _piezas(m, "SueloSalida")
		comprobar(salida.size() == 1 and not salida[0].enganchable and salida[0].poly[1].x - salida[0].poly[0].x >= 700.0, "suelo de salida para 4 mocos")
		comprobar(salida[0].pos - m.inicio == Vector2(100, 80), "la salida sobre su suelo, como hoy")
		comprobar(_piezas(m, "SueloMeta").size() == 1, "suelo de meta")
		comprobar(m.controles.size() >= 2, "semilla %d: controles en la bajada" % semilla)
		var y_previo := -INF
		for borde: Vector2 in m.salidas_descanso:
			comprobar(borde.y > y_previo, "semilla %d: cada descanso más abajo" % semilla)
			y_previo = borde.y
			var alcanza: bool = m.camino.any(func(c: Vector2) -> bool: return c.x > borde.x and c.distance_to(borde) <= PapelRope.LARGO_MAX - 20.0)
			comprobar(alcanza, "semilla %d: desde el descanso en %s no se alcanza ningún techo" % [semilla, borde])
		for h: Vector2 in m.huecos_sierra:
			comprobar(h.distance_to(m.inicio) >= 400.0, "semilla %d: sierra lejos de la salida" % semilla)
			for c: Vector2 in m.controles:
				comprobar(h.distance_to(c) >= 250.0, "semilla %d: sierra en %s cerca del control %s" % [semilla, h, c])
		for p in m.piezas:
			comprobar(m.limites.has_point(p.pos), "pieza %s dentro de los límites" % p.nombre)
			comprobar(m.caida_y - 100.0 > _bajo(p), "semilla %d: la franja que mata empieza bajo %s" % [semilla, p.nombre])
	comprobar(Generador.generar(3, "horizontal").huecos_sierra == [] and Generador.generar(3, "torre").huecos_sierra == [], "el campo existe en todas las formas")


func _bajo(p: Dictionary) -> float:
	var abajo := -INF
	for v: Vector2 in p.poly:
		abajo = maxf(abajo, v.y)
	return p.pos.y + abajo
