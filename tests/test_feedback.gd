extends Caso


func test_pintar_colorea_moco_y_efectos() -> void:
	var j: Node = load("res://scenes/jugador.tscn").instantiate()
	var rosa: Color = Jugador.COLORES[1]
	j.pintar(rosa)
	comprobar(j.get_node("Visual/Moco").color == rosa, "moco rosa")
	comprobar(j.get_node("Efectos/Salpicadura").color == rosa and j.get_node("Efectos/Goteo").color == rosa, "gotas rosas")
	var estela: Color = j.get_node("Efectos/Estela").default_color
	comprobar(is_equal_approx(estela.r, rosa.r) and estela.a < 1.0, "estela rosa translúcida")
	j.free()


func _hud() -> Node:
	var hud: Node = load("res://scenes/hud.tscn").instantiate()
	Engine.get_main_loop().root.add_child(hud)
	return hud


func test_cuenta_atras_visible() -> void:
	var hud := _hud()
	hud.cuenta_atras(12.3)
	comprobar(hud.get_node("Cuenta").visible and hud.get_node("Cuenta").text == "13", "cuenta 13 s")
	hud.cuenta_atras(-1.0)
	comprobar(not hud.get_node("Cuenta").visible, "sin cuenta, oculta")
	hud.free()


func test_marcador_con_victorias_y_tiempo() -> void:
	var hud := _hud()
	hud.marcador([[Color.RED, "TÚ", 2, 102.0], [Color.BLUE, "JUGADOR 2", 0, 150.0]])
	var m: Marcador = hud.get_node("Marcador")
	comprobar(m.visible and m.get_child_count() == 2, "una tarjeta con moco por fila")
	comprobar(m._derecha(m.filas[0]) == "2 VICTORIAS", "victorias de la primera")
	comprobar(m._derecha(m.filas[1]) == "0 · 2:30", "sin victorias, el tiempo total")
	hud.limpiar_tabla()
	comprobar(not m.visible, "Tab suelto, fuera")
	hud.free()


func test_marcador_da_mas_uno_al_ganador_y_recuerda_el_orden() -> void:
	var hud := _hud()
	var a := [Color.RED, "TÚ", 0, 100.0]
	var b := [Color.BLUE, "LUNA", 1, 90.0]
	var m: Marcador = hud.get_node("Marcador")
	hud.marcador([b, a], true)  # ronda 1: LUNA gana
	comprobar(Marcador.ganadores([b, a], {}) == [Marcador.clave(b)], "+1 solo para LUNA")
	var a2 := [Color.RED, "TÚ", 1, 190.0]
	var b2 := [Color.BLUE, "LUNA", 1, 200.0]
	comprobar(Marcador.ganadores([a2, b2], m.previo) == [Marcador.clave(a2)], "ronda 2: +1 solo para TÚ")
	hud.marcador([a2, b2], true)
	comprobar(m.desde[Marcador.clave(a2)][0] == 1 and m._puesto_visto(0) == 1.0, "TÚ parte del puesto 2 y sube")
	m.p = 1.0
	comprobar(m._puesto_visto(0) == 0.0, "al acabar, en su sitio")
	hud.marcador([a2, b2])  # Tab: sin animar
	comprobar(not m.animando and m._puesto_visto(0) == 0.0, "Tab no anima")
	hud.free()


func test_podio_escalones() -> void:
	var cuatro := Podio.escalones(4)
	comprobar(cuatro.map(func(e): return e.puesto) == [2, 1, 3], "2º izquierda, 1º centro, 3º derecha")
	comprobar(cuatro.filter(func(e): return e.copa).map(func(e): return e.puesto) == [1], "la copa es del 1º")
	comprobar(cuatro.filter(func(e): return e.ramo).map(func(e): return e.puesto) == [2], "el ramo es del 2º")
	var tiempos := cuatro.map(func(e): return e.retraso)
	comprobar(tiempos[2] < tiempos[0] and tiempos[0] < tiempos[1], "suben 3º, 2º y por último el 1º")
	comprobar(Podio.escalones(2).map(func(e): return e.puesto) == [2, 1], "con 2, solo 1º y 2º")
	comprobar(Podio.escalones(1).map(func(e): return e.puesto) == [1], "con 1, solo el 1º")
	var hud := _hud()
	hud.podio([[Color.RED, "TÚ", 3, 1.0], [Color.BLUE, "LUNA", 1, 1.0], [Color.GREEN, "PEPE", 0, 1.0], [Color.PINK, "ANA", 0, 1.0]])
	comprobar(hud.get_node("Podio").visible and hud.get_node("Podio").get_child_count() == 4, "un moco por puesto")
	hud.free()


func test_postal_de_ronda() -> void:
	var hud := _hud()
	hud.postal("RONDA 2 DE 5 · LA AZOTEA", 123, [[Color.RED, 1]])
	comprobar(hud.get_node("Postal").visible and hud.get_node("Postal").titulo.begins_with("RONDA 2"), "sale la postal")
	hud.ocultar_postal()
	comprobar(not hud.get_node("Postal").visible, "y se va")
	hud.free()


func test_sin_mejor_en_online() -> void:
	var hud := _hud()
	hud.mostrar(5.0, INF, false)
	comprobar(not "MEJOR" in hud.get_node("Tiempo").text.to_upper(), "online no enseña el mejor")
	hud.free()


func test_ayuda_de_controles() -> void:
	var hud := _hud()
	var ayuda: Label = hud.get_node_or_null("Ayuda")
	comprobar(ayuda != null and "CLIC" in ayuda.text and "E" in ayuda.text, "controles explicados en pantalla")
	hud.free()


func test_mira_se_puede_quitar_y_se_recuerda() -> void:
	comprobar(InputMap.has_action("mira"), "tecla para la mira (T)")
	var Mira: GDScript = load("res://scripts/mira.gd")
	var antes: bool = Mira.activa()
	Mira.alternar()
	comprobar(Mira.activa() != antes, "T la quita o la pone")
	var cfg := ConfigFile.new()
	cfg.load(Ajustes.ruta)
	comprobar(cfg.get_value("juego", "mira", true) == Mira.activa(), "se guarda para la próxima vez")
	Mira.alternar()  # dejarla como estaba
