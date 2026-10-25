extends Caso

const SEMILLAS := [1, 2, 3, 7, 11, 42, 99, 123, 500, 777]


func _nivel(semilla: int, tema: String) -> Node:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	var antes: Array = red.config.mapas
	red.config.mapas = [tema]
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	var s: int = red.semilla
	red.semilla = semilla
	Engine.get_main_loop().root.add_child(nivel)
	red.semilla = s
	red.config.mapas = antes
	return nivel


func _moviles(nivel: Node) -> Array:
	return nivel.get_node("Piezas").get_children().filter(func(n: Node) -> bool: return n is Barco or n is Liana or n is Globo)


func test_mismo_mapa_mismos_moviles() -> void:
	for s in SEMILLAS:
		var m := Generador.generar(s)
		comprobar(Moviles.barcos(m, s) == Moviles.barcos(m, s) and Moviles.lianas(m, s) == Moviles.lianas(m, s), "determinista %d" % s)
		comprobar(Moviles.ropas(m, s) == Moviles.ropas(m, s) and Moviles.globos(m, s) == Moviles.globos(m, s), "determinista (2) %d" % s)
		comprobar(Moviles.globos(m, s).size() <= 6, "pocos globos")


# Una semilla en la que el elemento sí aparece (en torres y pozos, por ejemplo, no caben lianas)
func _con(f: Callable) -> int:
	for s in 200:
		if not f.call(Generador.generar(s), s).is_empty():
			return s
	return -1


func test_cada_tema_solo_los_suyos() -> void:
	var quien := {"mar": Barco, "jungla": Liana, "noche": Globo}
	var busca := {"mar": Moviles.barcos, "jungla": Moviles.lianas, "noche": Moviles.globos}
	for tema: String in quien:
		var s := _con(busca[tema])
		var nivel := _nivel(s, tema)
		var n := 0
		for c in nivel.get_node("Piezas").get_children():
			for t: String in quien:
				if is_instance_of(c, quien[t]) and not (c is Prenda):
					comprobar(t == tema, "%s en el tema %s" % [t, tema])
					n += 1
		comprobar(n > 0, "el tema %s tiene lo suyo (semilla %d)" % [tema, s])
		nivel.free()
	var s := _con(Moviles.ropas)
	var azotea := _nivel(s, "azotea")
	comprobar(azotea.get_node("Piezas").get_children().all(func(c: Node) -> bool: return not (c is Barco or c is Globo) and (not c is Liana or c is Prenda)), "la azotea solo tiene ropa")
	comprobar(azotea.get_node("Piezas").get_children().any(func(c: Node) -> bool: return c is Prenda), "la azotea tiene ropa")
	azotea.free()
	var cueva := _nivel(s, "cueva")
	comprobar(_moviles(cueva).is_empty(), "la cueva sin moviles de la parte A")
	cueva.free()


func test_no_tapan_el_camino() -> void:
	for s in SEMILLAS:
		var m := Generador.generar(s)
		for b: Dictionary in Moviles.barcos(m, s):
			comprobar(not Moviles.ocupado(m, Rect2(b.pos.x - 70.0, b.pos.y - 170.0, b.riel + 140.0, 200.0)), "barco libre")
			comprobar(b.pos.y >= m.limites.end.y - 1.0, "el barco va por abajo")
		for l: Dictionary in Moviles.lianas(m, s):
			comprobar(l.pivote.y < m.limites.end.y and not Moviles.ocupado(m, Rect2(l.pivote.x - 110.0, l.pivote.y - 30.0, 220.0, l.largo + 60.0)), "liana libre")


func test_barco_va_y_vuelve() -> void:
	var b := Barco.new()
	b.riel = 1000.0
	b.fase = 0.0
	comprobar(b.posicion_en(0.0) == 0.0, "sale de su sitio")
	comprobar(absf(b.posicion_en(Barco.PERIODO / 2.0) - 1000.0) < 0.01, "llega al otro lado")
	comprobar(absf(b.posicion_en(Barco.PERIODO)) < 0.01, "vuelve")
	b.free()


func test_liana_se_mece_y_no_se_estira() -> void:
	var l := Liana.new()
	l.pivote = Vector2(100, 50)
	l.largo = 200.0
	var maxa := 0.0
	for k in 40:
		var t := k * 0.1
		comprobar(absf(l.punta_en(t).distance_to(l.pivote) - 200.0) < 0.01, "el largo no cambia")
		maxa = maxf(maxa, absf(l.angulo_en(t)))
	comprobar(maxa > 0.3 and maxa <= l.amplitud + 0.001, "se mece dentro de su amplitud")
	l.free()


func test_globo_sube_en_bucle_y_a_veces_no_esta() -> void:
	var g := Globo.new()
	g.abajo = 1000.0
	g.alto = 1400.0
	var y0 := g.posicion_en(0.0).y
	comprobar(g.posicion_en(5.0).y < y0, "sube")
	var ausente := 0
	for k in 400:
		if not g.presente_en(k * 0.1):
			ausente += 1
	comprobar(ausente > 0 and ausente < 100, "solo desaparece un rato al reventar/salir")
	comprobar(absf(g.posicion_en(1.0).y - g.posicion_en(0.0).y) < Moviles.VELOCIDAD_GLOBO * 1.0 + 1.0, "sube despacio")
	g.free()


func test_papel_sigue_a_lo_que_se_mueve_y_se_suelta() -> void:
	var root: Node = Engine.get_main_loop().root
	var l := Liana.new()
	l.pivote = Vector2(0, 0)
	var j: Jugador = load("res://scenes/jugador.tscn").instantiate()
	root.add_child(l)
	root.add_child(j)
	j.papel = PapelRope.new(l.global_position, 100.0)
	j._papel_cuerpo = l
	j._papel_local = Vector2.ZERO
	l.position += Vector2(30, 40)
	j._seguir_ancla()
	comprobar(j.papel != null and j.papel.ancla == l.global_position, "el ancla va con el cuerpo")
	l.remove_from_group("enganchable")
	j._seguir_ancla()
	comprobar(j.papel == null, "si deja de ser enganchable, se suelta")
	l.free()
	j.free()
