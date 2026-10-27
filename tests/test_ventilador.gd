extends Caso

const FORMAS := ["horizontal", "bajada", "hibrido", "montaña", "torre", "pozo"]


func test_fuerza_del_chorro() -> void:
	comprobar(Ventilador.fuerza_en(0.0) == 1.0 and Ventilador.fuerza_en(0.5) == 1.0, "entero hasta la mitad")
	comprobar(Ventilador.fuerza_en(0.75) > 0.0 and Ventilador.fuerza_en(0.75) < 1.0 and Ventilador.fuerza_en(1.0) == 0.0, "se apaga en la punta")
	comprobar(Ventilador.ACEL_ARRIBA > 1400.0 and Ventilador.ACEL_ARRIBA <= 2400.0, "soplando arriba gana a la gravedad sin pasarse")
	var v := Ventilador.new()
	v.dir = Vector2.UP
	v.largo = 600.0
	comprobar(v.aceleracion_en(Vector2(0, -100)).y < -1400.0, "abajo del chorro, hacia arriba y más que la gravedad")
	comprobar(v.aceleracion_en(Vector2(0, -590)).y > -1400.0, "en la punta flota o cae")
	v.dir = Vector2.RIGHT
	comprobar(v.aceleracion_en(Vector2(100, 0)) == Vector2(Ventilador.ACEL_LADO, 0.0), "de lado empuja hacia donde sopla")
	v.free()


func test_ventiladores_deterministas_y_en_sitio_libre() -> void:
	var total := 0
	for f in FORMAS:
		for s in 25:
			var m := Generador.generar(s, f)
			var a := Ventilador.nuevos(s, m, null)
			var b := Ventilador.nuevos(s, m, null)
			comprobar(a.size() == b.size() and a.size() <= 3, "%s %d: entre 0 y 3 ventiladores" % [f, s])
			if f in ["torre", "pozo"]:
				comprobar(a.is_empty(), "%s %d: ni torre ni pozo llevan ventilador" % [f, s])
			for i in a.size():
				var v: Ventilador = a[i]
				total += 1
				comprobar(v.position == b[i].position and v.dir == b[i].dir and v.largo == b[i].largo, "%s %d: ventilador determinista" % [f, s])
				comprobar(not Moviles.ocupado(m, v.zona()), "%s %d: ventilador sobre algo del mapa" % [f, s])
				comprobar(not v.zona().grow(399.0).has_point(m.inicio) and not v.zona().grow(399.0).has_point(m.meta), "%s %d: ventilador cerca de la salida o la meta" % [f, s])
				comprobar(v.largo >= 500.0 and v.largo <= 700.0, "largo del chorro")
				for j in i:
					comprobar(not a[j].zona().intersects(v.zona()), "%s %d: dos ventiladores se pisan" % [f, s])
			for n: Ventilador in a + b:
				n.free()
	comprobar(total > 10, "salen ventiladores: %d" % total)
