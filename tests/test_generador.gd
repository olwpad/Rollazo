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
