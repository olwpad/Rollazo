extends Caso

const SEMILLAS := [3, 11, 42, 777, 5150, 90210]


func _mapa(semilla: int) -> Dictionary:
	return Generador.generar(semilla)


func test_marea_nunca_tapa_el_camino_y_es_determinista() -> void:
	for s in SEMILLAS:
		var m := _mapa(s)
		var a := Marea.nueva(s, m, null)
		var b := Marea.nueva(s, m, null)
		comprobar(a.fase == b.fase and a.sube == b.sube and a.base_y == b.base_y, "marea determinista (semilla %d)" % s)
		var techo_bajo := -INF
		for c: Vector2 in m.camino:
			techo_bajo = maxf(techo_bajo, c.y)
		var mas_alta := INF
		for k in 200:
			mas_alta = minf(mas_alta, a.y_en(k * Marea.PERIODO / 200.0))
		comprobar(mas_alta >= techo_bajo + Marea.MARGEN - 0.01 or a.sube == 0.0, "marea alta bajo el techo más bajo (semilla %d)" % s)
		comprobar(a.y_en(0.0) <= a.base_y + 0.01 and a.y_en(Marea.PERIODO * (0.5 - a.fase)) <= a.base_y - a.sube + 0.01, "la marea sube hasta su máximo")
		a.free()
		b.free()


func test_estalactita_avisa_cae_y_vuelve() -> void:
	var e := Estalactita.new()
	e.fase = 0.0
	comprobar(e.fase_en(0.0) == Estalactita.Fase.CUELGA and e.caido_en(1.0) == 0.0, "cuelga quieta")
	comprobar(e.fase_en(Estalactita.T_AVISO + 0.1) == Estalactita.Fase.TIEMBLA, "avisa antes de caer")
	comprobar(Estalactita.T_CAE - Estalactita.T_AVISO >= 0.59, "el aviso dura ~0,6 s")
	comprobar(e.fase_en(Estalactita.T_CAE + 0.1) == Estalactita.Fase.CAE and e.caido_en(Estalactita.T_CAE + 0.3) > 0.0, "cae")
	comprobar(e.fase_en(Estalactita.T_CAE + Estalactita.SEG_CAIDA + 0.1) == Estalactita.Fase.AUSENTE, "tras caer no está")
	comprobar(e.fase_en(Estalactita.T_CRECE + 0.1) == Estalactita.Fase.CRECE, "vuelve a crecer")
	comprobar(e.fase_en(Estalactita.PERIODO + 0.1) == Estalactita.Fase.CUELGA, "y el ciclo se repite")
	e.free()
	var m := _mapa(42)
	var x := Estalactita.nuevas(42, m, null)
	var y := Estalactita.nuevas(42, m, null)
	comprobar(x.size() == y.size() and x.all(func(n: Estalactita) -> bool: return n.position == y[x.find(n)].position and n.fase == y[x.find(n)].fase), "estalactitas deterministas")
	for n: Estalactita in x + y:
		n.free()


func test_paloma_cruza_dentro_de_la_ronda_y_empuja_una_vez() -> void:
	var m := _mapa(11)
	var v := Paloma.nuevas(11, m, null)
	comprobar(v.size() >= 3 and v.size() <= 5, "entre 3 y 5 palomas")
	var w := Paloma.nuevas(11, m, null)
	for i in v.size():
		comprobar(v[i].y == w[i].y and v[i].fase == w[i].fase and v[i].posicion_en(7.3) == w[i].posicion_en(7.3), "paloma determinista")
		comprobar(v[i].posicion_en(7.3).x >= v[i].desde - 0.1 and v[i].posicion_en(7.3).x <= v[i].desde + v[i].largo + 0.1, "vuela dentro de su recorrido")
	var p: Paloma = v[0]
	var moco := CharacterBody2D.new()
	moco.name = "1"
	comprobar(p.empujar(moco) and moco.velocity.x == Paloma.EMPUJE.x * p.dir, "la paloma empuja")
	comprobar(not p.empujar(moco), "no empuja dos veces seguidas")
	moco.free()
	for n: Paloma in v + w:
		n.free()
	for t in Temas.LISTA:  # cada tema su ave, con cuerpo y pico distintos
		comprobar(Paloma.ASPECTO.has(t), "aspecto de ave para %s" % t)
	var vistos := {}
	for t in Temas.LISTA:
		vistos[Paloma.ASPECTO[t].cuerpo] = true
	comprobar(vistos.size() == Temas.LISTA.size(), "cada tema un color de ave distinto")


func test_apagones_nunca_dos_techos_seguidos() -> void:
	for s in SEMILLAS:
		var m := _mapa(s)
		var n: int = m.camino.size()
		var idx := Apagon.indices(s, n)
		comprobar(idx == Apagon.indices(s, n), "apagones deterministas")
		for i in idx:
			comprobar(not (i + 1) in idx and i > 0 and i < n - 1, "ningún apagón junto a otro ni en los extremos (semilla %d)" % s)
	var a := Apagon.new()
	a.fase = 0.0
	comprobar(a.apagado_en(0.1) and not a.apagado_en(Apagon.APAGADO + 0.1) and a.apagado_en(Apagon.PERIODO + 0.1), "apagado un rato y vuelve a encenderse")
	a.free()


func test_cada_elemento_solo_en_su_tema() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7794)
	var por_tema := {"mar": "Marea", "cueva": "Estalactita", "azotea": "", "noche": "Guirnalda", "jungla": ""}
	for tema in por_tema:
		red.config.mapas = [tema]
		var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
		Engine.get_main_loop().root.add_child(nivel)
		var clases := {"Marea": 0, "Estalactita": 0, "Paloma": 0, "Guirnalda": 0, "Apagon": 0}
		for hijo in nivel.get_node("Piezas").get_children():
			for c in clases:
				if hijo.get_script() != null and hijo.get_script().get_global_name() == c:
					clases[c] += 1
		for c in clases:
			if c == "Paloma":  # las aves salen en todos los temas
				comprobar(clases[c] >= 3, "aves en tema %s: %d" % [tema, clases[c]])
				continue
			var debe: bool = c == por_tema[tema] or (tema == "noche" and c == "Apagon")
			comprobar(clases[c] == 0 if not debe else (clases[c] > 0 or c in ["Estalactita", "Apagon"]), "%s en tema %s: %d" % [c, tema, clases[c]])
		Engine.get_main_loop().root.remove_child(nivel)
		nivel.free()
