extends Caso


func test_misma_semilla_mismo_mapa() -> void:
	var a := Generador.generar(42)
	var b := Generador.generar(42)
	comprobar(var_to_str(a) == var_to_str(b), "los 4 PCs construyen lo mismo")
	comprobar(var_to_str(a) != var_to_str(Generador.generar(43)), "otra semilla, otro mapa")


func test_largo_con_controles_y_caida() -> void:
	for semilla in 20:
		var m := Generador.generar(semilla)
		comprobar(m.meta.x >= 7500.0, "largo (semilla %d, meta %.0f)" % [semilla, m.meta.x])
		comprobar(m.controles.size() >= 2, "puntos de control (semilla %d)" % semilla)
		comprobar(m.caida_x - m.caida_ancho / 2.0 < 0.0 and m.caida_x + m.caida_ancho / 2.0 > m.meta.x + 500.0, "la caída cubre todo (semilla %d)" % semilla)


func test_no_todo_son_rectangulos() -> void:
	var raros := 0
	for p in Generador.generar(7).piezas:
		var poly: PackedVector2Array = p.poly
		if poly.size() != 4 or not is_zero_approx(poly[0].y - poly[1].y):
			raros += 1
	comprobar(raros >= 4, "formas irregulares: %d" % raros)


# El camino principal siempre se puede recorrer: cada techo está al alcance del anterior,
# y desde cada descanso se alcanza el techo siguiente con el papel.
func test_siempre_alcanzable() -> void:
	for semilla in 50:
		var m := Generador.generar(semilla)
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
		var m := Generador.generar(semilla)
		for pilar in _piezas(m, "Pilar"):
			var techo: Vector2 = m.camino.reduce(func(a: Vector2, c: Vector2) -> Vector2: return c if absf(c.x - pilar.pos.x) < absf(a.x - pilar.pos.x) else a)
			comprobar(_alto(pilar) - techo.y >= 230.0, "semilla %d: hueco del embudo %.0f px" % [semilla, _alto(pilar) - techo.y])
			comprobar(m.controles.size() > 0 and pilar.pos.x > m.controles[0].x, "semilla %d: embudo antes del primer control" % semilla)


func test_sin_bloques_encima_de_descansos_ni_atajos_tras_el_ultimo_techo() -> void:
	for semilla in 60:
		var m := Generador.generar(semilla)
		for b in _piezas(m, "Bloque"):
			for d in _piezas(m, "Descanso"):
				var encima: bool = absf(b.pos.x - d.pos.x) < 220.0 and d.pos.y - b.pos.y < 250.0
				comprobar(not encima, "semilla %d: bloque en %s encima del descanso" % [semilla, b.pos])
		for a in _piezas(m, "Atajo"):
			comprobar(a.pos.x < m.camino.back().x, "semilla %d: atajo tras el último techo lanza más allá de la meta" % semilla)


func test_suelo_de_meta_cerca_del_ultimo_techo() -> void:
	for semilla in 60:
		var m := Generador.generar(semilla)
		var suelo: Dictionary = _piezas(m, "SueloMeta")[0]
		var borde: float = suelo.pos.x - 350.0
		comprobar(borde - m.camino.back().x <= 150.0, "semilla %d: hueco hasta el suelo de meta %.0f px" % [semilla, borde - m.camino.back().x])
