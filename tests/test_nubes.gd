extends Caso

# Todas las formas, varias semillas: las nubes de tormenta salen del mapa sin azar.
const FORMAS := ["horizontal", "bajada", "torre", "pozo", "montaña", "hibrido"]


func _dentro(m: Dictionary, punto: Vector2) -> bool:
	return m.nubes.any(func(n: Dictionary) -> bool: return Geometry2D.is_point_in_polygon(punto, n.poly))


func _toca(n: Dictionary, p: Dictionary) -> bool:
	return not Geometry2D.intersect_polygons(n.poly, Generador.poly_global(p)).is_empty()


func test_nubes_deterministas() -> void:
	for f in FORMAS:
		for s in 8:
			comprobar(var_to_str(Generador.generar(s, f).nubes) == var_to_str(Generador.generar(s, f).nubes), "nubes deterministas (%s %d)" % [f, s])


func test_sin_nubes_en_torre_ni_pozo() -> void:
	for f in ["torre", "pozo"]:
		for s in 20:
			comprobar(Generador.generar(s, f).nubes.is_empty(), "%s %d: la torre y el pozo no llevan nubes" % [f, s])
	var hay := false
	for f in ["horizontal", "bajada"]:
		for s in 10:
			var m := Generador.generar(s, f)
			hay = hay or m.nubes.any(func(n: Dictionary) -> bool: return n.tipo == "techo") and m.nubes.any(func(n: Dictionary) -> bool: return n.tipo == "cielo")
	comprobar(hay, "horizontal y bajada llevan nubes de techo y de cielo")


func test_las_nubes_no_tocan_torre_pozo_ni_el_juego_legitimo() -> void:
	for f in FORMAS:
		for s in 25:
			var m := Generador.generar(s, f)
			var que := "%s %d" % [f, s]
			# Nada de torre ni pozo: ni sus salientes ni sus paredes
			for t: Dictionary in m.tramos:
				if t.tipo in ["torre", "pozo"]:
					for i in range(t.i0, t.i1):
						for p in Generador.techos_en(m, m.camino[i]):
							comprobar(not m.nubes.any(func(n: Dictionary) -> bool: return _toca(n, p)), "%s: nube sobre un saliente de %s" % [que, t.tipo])
			var puntos: Array = m.controles + [m.inicio, m.meta]
			for k in 4:
				puntos.append(m.inicio + Vector2(k * 90.0, 0.0))  # donde salen los mocos
			puntos += m.burbujas.map(func(b: Dictionary) -> Vector2: return b.pos)
			for v: Vector2 in puntos:
				comprobar(not _dentro(m, v), "%s: nube cubre %s" % [que, v])
			for p: Dictionary in m.piezas:
				if p.nombre.begins_with("Atajo") or p.nombre.begins_with("Descanso") or p.nombre.begins_with("Suelo"):
					comprobar(not m.nubes.any(func(n: Dictionary) -> bool: return _toca(n, p)), "%s: nube sobre %s" % [que, p.nombre])
				if p.nombre.begins_with("Atajo"):  # el cielo prohibido empieza bien por encima de los atajos
					for n: Dictionary in m.nubes:
						if n.tipo == "cielo":
							var c := Generador.caja_de(p)
							if c.end.x > n.poly[0].x and c.position.x < n.poly[1].x:
								comprobar(n.poly[2].y <= c.position.y - Generador.NUBE_MARGEN + 0.01, "%s: el cielo prohibido roza un atajo" % que)


func test_nubes_de_techo_cubren_la_cara_de_arriba() -> void:
	for s in 15:
		var m := Generador.generar(s, "horizontal")
		for i in m.camino.size():
			for p in Generador.techos_en(m, m.camino[i]):
				var alta := Vector2(0.0, INF)
				for v in Generador.poly_global(p):
					alta = v if v.y < alta.y else alta
				comprobar(_dentro(m, alta - Vector2(0.0, Generador.NUBE_ALTO / 2.0)), "semilla %d: techo %d sin nube encima" % [s, i])
