extends Caso


func test_cinco_mapas_con_nombre() -> void:
	comprobar(Temas.LISTA == ["azotea", "noche", "cueva", "mar", "jungla"], "los 5 mapas")
	for t in Temas.LISTA:
		comprobar(Temas.DATOS[t].nombre != "", "nombre de " + t)
	comprobar(Temas.DATOS.azotea.nombre == "LA AZOTEA", "el de siempre se sigue llamando igual")


func test_cada_ronda_otro_mapa() -> void:
	var lista := ["azotea", "cueva", "jungla"]
	var vistos := []
	for r in range(1, 4):
		vistos.append(Temas.de_ronda(lista, 77, r))
	comprobar(vistos.size() == 3 and vistos[0] != vistos[1] and vistos[1] != vistos[2] and vistos[0] != vistos[2], "no se repite hasta pasar por todos: %s" % [vistos])
	comprobar(Temas.de_ronda(["mar"], 5, 9) == "mar", "con uno solo, siempre ese")
	comprobar(Temas.de_ronda([], 5, 1) == "azotea", "lista vacía: el de siempre")


func test_config_de_mapas_y_aros() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7794)
	comprobar(red.config.mapas == Temas.LISTA and not red.config.aros, "por defecto todos los mapas y, de momento, sin aros")
	red.poner_mapas(["cueva", "mar"])
	comprobar(red.config.mapas == ["cueva", "mar"], "el anfitrión elige mapas")
	red.poner_mapas([])
	comprobar(red.config.mapas == ["cueva", "mar"], "al menos uno")
	red.poner_mapas(["cueva", "inventado"])
	comprobar(red.config.mapas == ["cueva", "mar"], "solo mapas que existen")
	red.poner_aros(false)
	comprobar(not red.config.aros, "se pueden quitar los aros")
	red.salir()
	comprobar(red.config.mapas == Temas.LISTA, "al salir vuelve a lo de siempre")


func test_aros_en_el_hueco_entre_techos() -> void:
	for semilla in 20:
		var m := Generador.generar(semilla, "horizontal")
		comprobar(m.aros.size() >= 2, "semilla %d: aros %d" % [semilla, m.aros.size()])
		for a: Dictionary in m.aros:
			comprobar(a.pos.x > Generador.INICIO_FIN + 400.0 and a.pos.x < m.meta.x - 300.0, "semilla %d: aro lejos de salida y meta" % semilla)
			comprobar(a.mov in ["quieto", "sube"], "movimiento conocido")
			for p: Dictionary in m.piezas:
				comprobar(a.pos.distance_to(p.pos) > 190.0, "semilla %d: aro %s pegado a %s" % [semilla, a.pos, p.nombre])
	# En las otras formas puede no haber hueco para aros, pero nunca dentro de una pieza ni fuera del mapa
	for forma in Generador.FORMAS:
		for semilla in 20:
			var m := Generador.generar(semilla, forma)
			for a: Dictionary in m.aros:
				comprobar(m.limites.has_point(a.pos), "%s %d: aro dentro de los límites" % [forma, semilla])
				for p: Dictionary in m.piezas:
					comprobar(a.pos.distance_to(p.pos) > 190.0 and not Geometry2D.is_point_in_polygon(a.pos - p.pos, p.poly), "%s %d: aro %s en %s" % [forma, semilla, a.pos, p.nombre])
	comprobar(Generador.generar(4).piezas == Generador.generar(4).piezas, "los aros no cambian el resto del mapa")


func test_recorrido_con_tema() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.config.mapas = ["cueva"]
	red.config.aros = true  # quitados por defecto, pero el código sigue
	red.semilla = 2  # sale horizontal, con huecos para aros (la 3 es una montaña, sin ellos)
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	comprobar(nivel.tema == "cueva", "monta la cueva")
	comprobar(nivel.get_node("Piezas").find_children("Aro*", "", false, false).size() > 0, "la cueva trae aros")
	nivel.free()
	red.config.mapas = ["mar"]
	nivel = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	comprobar(nivel.tema == "mar" and nivel.get_node("Piezas").find_children("Aro*", "", false, false).is_empty(), "el mar va sin aros")
	nivel.free()
	red.config = red.CONFIG_INICIAL.duplicate(true)


func test_el_aro_quema_el_papel() -> void:
	var n := Node2D.new()
	Engine.get_main_loop().root.add_child(n)
	var j: Jugador = load("res://scenes/jugador.tscn").instantiate()
	j.name = "1"
	n.add_child(j)
	j.global_position = Vector2(100, 0)
	j.papel = PapelRope.new(Vector2(100, -300), 300.0)
	j.quemarse()
	comprobar(j.papel == null, "se le quema el papel")
	comprobar(j.get_node("Visual").modulate.r < 0.8, "se le ve chamuscado")
	comprobar(j.get_node("Efectos/Humo").emitting, "echa humo")
	n.free()


func test_sierra_en_riel_va_y_vuelve() -> void:
	var s := Sierra.new()
	s.riel = Vector2(200, 0)
	comprobar(s.posicion_en(0.0).is_equal_approx(Vector2.ZERO), "empieza en su sitio")
	comprobar(s.posicion_en(1.5).x > 150.0, "a mitad llega al otro lado")
	comprobar(s.posicion_en(3.0).x < 50.0, "y vuelve")
	s.riel = Vector2.ZERO
	comprobar(s.posicion_en(1.5) == Vector2.ZERO, "la quieta no se mueve")
	s.free()


func test_el_nivel_monta_las_sierras() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	var semilla := 0
	while Generador.generar(semilla).sierras.size() < 2:
		semilla += 1
	red.semilla = semilla
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	var sierras: Array = nivel.get_node("Piezas").find_children("Sierra*", "", false, false)
	comprobar(sierras.size() == Generador.generar(semilla).sierras.size(), "una sierra por cada una del mapa")
	comprobar(sierras[0] is Sierra and sierras[0].body_entered.get_connections().size() > 0, "y tocarla hace algo")
	nivel.free()
	red.semilla = 0


func test_las_sierras_siguen_cuando_llega_el_moco_local() -> void:
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	nivel.llegada(nivel.multiplayer.get_unique_id(), 1, 5.0)
	var antes: float = nivel.reloj_ronda
	nivel._physics_process(0.5)
	comprobar(nivel.tiempo == 5.0, "el cronómetro local se para en la meta")
	comprobar(is_equal_approx(nivel.reloj_ronda, antes + 0.5), "pero el reloj de las sierras sigue (el anfitrión decide con él)")
	nivel.free()
