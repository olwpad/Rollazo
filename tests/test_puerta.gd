extends Caso

const FORMAS := ["horizontal", "bajada", "hibrido", "montaña", "torre", "pozo"]


func test_ciclo_de_la_abertura() -> void:
	comprobar(Puerta.abertura_en(0.0) == 0.0 and is_equal_approx(Puerta.abertura_en(0.25), 0.5), "abriendo")
	comprobar(Puerta.abertura_en(0.5) == 1.0 and Puerta.abertura_en(2.0) == 1.0 and Puerta.abertura_en(2.99) == 1.0, "abierta 2,5 s")
	comprobar(is_equal_approx(Puerta.abertura_en(3.25), 0.5), "cerrando")
	comprobar(Puerta.abertura_en(3.5) == 0.0 and Puerta.abertura_en(4.99) == 0.0, "cerrada 1,5 s")
	comprobar(is_equal_approx(Puerta.abertura_en(5.0 + 2.0), 1.0) and Puerta.abertura_en(-1.5) == 0.0, "periódica (también con t negativo)")


func test_puertas_deterministas_y_en_sitio_libre() -> void:
	var total := 0
	var mapas := 0
	var con_puerta := 0
	for f in FORMAS:
		for s in 60:
			var m := Generador.generar(s, f)
			var a := Puerta.nuevas(s, m, null)
			var b := Puerta.nuevas(s, m, null)
			comprobar(a.size() == b.size() and a.size() <= 2, "%s %d: entre 0 y 2 puertas" % [f, s])
			if f in ["torre", "pozo"]:
				comprobar(a.is_empty(), "%s %d: ni torre ni pozo llevan puerta" % [f, s])
			if f in ["horizontal", "bajada"]:
				mapas += 1
				con_puerta += 1 if not a.is_empty() else 0
			var otras := []
			for v: Ventilador in Ventilador.nuevos(s, m, null):
				otras.append(v.zona())
				v.free()
			for t: Trampolin in Trampolin.nuevos(s, m, null):
				otras.append(t.zona())
				t.free()
			for i in a.size():
				var p: Puerta = a[i]
				total += 1
				comprobar(p.position == b[i].position and p.fase == b[i].fase, "%s %d: puerta determinista" % [f, s])
				comprobar(p.position.distance_to(m.inicio) >= 500.0 and p.position.distance_to(m.meta) >= 500.0, "%s %d: puerta cerca de la salida o la meta" % [f, s])
				var columna := Rect2(p.position.x - Puerta.ANCHO / 2.0, p.arriba_y, Puerta.ANCHO, p.abajo_y - p.arriba_y)
				for pieza: Dictionary in m.piezas:
					comprobar(Geometry2D.intersect_polygons(Generador.poly_global(pieza), PackedVector2Array([columna.position, Vector2(columna.end.x, columna.position.y), columna.end, Vector2(columna.position.x, columna.end.y)])).is_empty(), "%s %d: la puerta cruza la pieza %s" % [f, s, pieza.nombre])
				for z: Rect2 in otras:
					comprobar(not z.intersects(columna), "%s %d: puerta sobre un ventilador o trampolín" % [f, s])
				comprobar(p.abajo_y > p.position.y + Puerta.HUECO and p.arriba_y < p.position.y - Puerta.HUECO, "mitades que llegan lejos")
				for j in i:
					comprobar(absf(a[j].position.x - p.position.x) > 150.0, "%s %d: dos puertas seguidas" % [f, s])
			for n: Puerta in a + b:
				n.free()
	var parte := float(con_puerta) / mapas
	comprobar(total > 10, "salen puertas: %d" % total)
	comprobar(parte > 0.25 and parte < 0.45, "una de cada tres: %.2f" % parte)
