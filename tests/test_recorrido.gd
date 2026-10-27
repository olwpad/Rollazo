extends Caso

const REC := preload("res://scripts/recorrido.gd")


func test_recorrido_tiene_lo_necesario() -> void:
	var e: PackedScene = load("res://scenes/recorrido_prueba.tscn")
	comprobar(e != null, "existe recorrido_prueba.tscn")
	if e == null:
		return
	var n := e.instantiate()
	for nombre in ["Jugadores", "Inicio", "Meta", "Caida", "Controles", "HUD"]:
		comprobar(n.get_node_or_null(nombre) != null, "falta " + nombre)
	n.free()


func test_formato_tiempo() -> void:
	var hud_script: GDScript = load("res://scripts/hud.gd")
	comprobar(hud_script != null and hud_script.formatear(3.456) == "03.46", "03.46")
	comprobar(hud_script != null and hud_script.formatear(INF) == "--.--", "sin mejor tiempo")


func test_boton_y_tecla_para_volver_al_menu() -> void:
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	comprobar(nivel.get_node_or_null("HUD/Menu") is Button, "botón de menú en el HUD")
	comprobar(InputMap.has_action("volver_menu"), "tecla para volver al menú")
	nivel.free()


func test_caben_seis_mocos_en_la_salida() -> void:
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	var suelo: Node2D = nivel.get_node("SueloInicio")
	var borde: float = suelo.position.x + suelo.get_node("Forma").shape.size.x / 2.0
	var ultimo: float = nivel.get_node("Inicio").position.x + REC.posicion_salida(5, 6, 0)
	comprobar(ultimo + 25.0 < borde, "el 6.º moco (x=%.0f) sale encima del suelo (borde %.0f)" % [ultimo, borde])
	nivel.free()


func test_salida_junta_centrada_y_rotando() -> void:
	for n in range(1, 7):
		for ronda in range(1, 8):
			var xs := []
			for i in n:
				xs.append(REC.posicion_salida(i, n, ronda))
			var suma := 0.0
			for x in xs:
				suma += x
			comprobar(absf(suma) < 0.001, "n=%d ronda %d: centrados en Inicio" % [n, ronda])
			xs.sort()
			for k in range(1, n):
				comprobar(xs[k] - xs[k - 1] >= 40.0, "n=%d: ni se pisan ni rebotan al salir" % n)
			comprobar(xs[n - 1] - xs[0] <= 5 * 44.0 + 0.001, "n=%d: casi juntos" % n)
	comprobar(REC.posicion_salida(0, 6, 1) != REC.posicion_salida(0, 6, 2), "cada ronda cambia el puesto")


func test_meta_alta_para_no_sobrevolarla() -> void:
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	comprobar(nivel.get_node("Meta/Forma").shape.size.y >= 1200.0, "la meta cubre de arriba abajo")
	nivel.free()


func _semilla_de(forma: String) -> int:
	for s in 500:
		if Generador.generar(s).forma == forma:
			return s
	return -1


# El nivel de verdad montado con esa semilla (en el árbol: _ready llama a construir).
func _nivel_construido(semilla: int) -> Node:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	var antes: int = red.semilla
	red.semilla = semilla
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	red.semilla = antes
	return nivel


func test_construir_se_adapta_a_la_forma() -> void:
	for forma in ["torre", "bajada"]:
		var s := _semilla_de(forma)
		var m := Generador.generar(s)
		var nivel := _nivel_construido(s)
		comprobar(nivel.get_node("Inicio").position == m.inicio, forma + ": salida movida")
		comprobar(nivel.get_node("Caida").position.y == m.caida_y, forma + ": caída bajo el mapa")
		comprobar(nivel.get_node("Meta/Forma").shape.size == m.meta_tam, forma + ": meta a medida (no 1200 de alto en una torre)")
		var suelo: Node2D = nivel.get_node("SueloInicio")
		comprobar(absf(suelo.position.y - m.inicio.y) < 120.0, forma + ": suelo de salida bajo los mocos")
		comprobar(nivel.get_node("Piezas").find_children("SueloSalida*", "", false, false).is_empty(), forma + ": un solo suelo de salida")
		comprobar(nivel.has_method("_mandar_a_mirar"), "existe _mandar_a_mirar")
		nivel.free()


func test_caben_seis_mocos_en_la_salida_de_una_bajada() -> void:
	var nivel := _nivel_construido(_semilla_de("bajada"))
	var suelo: Node2D = nivel.get_node("SueloInicio")
	var borde: float = suelo.position.x + suelo.get_node("Forma").shape.size.x / 2.0
	var inicio: Vector2 = nivel.get_node("Inicio").position
	comprobar(inicio.x + REC.posicion_salida(5, 6, 0) + 25.0 < borde, "el 6.º moco sale encima del suelo de la bajada")
	comprobar(suelo.position.y > inicio.y, "el suelo está debajo de la salida")
	nivel.free()


func test_meta_y_caida_no_se_contagian_entre_niveles() -> void:
	var nivel := _nivel_construido(_semilla_de("torre"))
	var limpio: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	comprobar(limpio.get_node("Meta/Forma").shape.size.y >= 1200.0, "una torre no encoge la meta de otro nivel")
	limpio.free()
	nivel.free()


func _nivel_solo() -> Node:
	return _nivel_construido(7)


func test_solo_llegar_trae_mapa_nuevo() -> void:
	var nivel := _nivel_solo()
	var antes: int = nivel.semilla_actual
	nivel.llegada(1, 1, 12.0)
	comprobar(nivel.jugador_local().congelado, "tras la meta no te devuelve a un control")
	nivel._mapa_nuevo_solo()
	comprobar(nivel.semilla_actual != antes and nivel.mejor == INF and nivel.ronda == 2, "otro mapa, otro tema, mejor de cero")
	nivel.free()


func test_solo_r_tras_llegar_repite_el_mismo() -> void:
	var nivel := _nivel_solo()
	var antes: int = nivel.semilla_actual
	nivel.llegada(1, 1, 12.0)
	nivel.reiniciar()  # lo que hace la R
	comprobar(nivel.semilla_actual == antes and nivel.mejor == 12.0, "mismo mapa y se guarda el mejor")
	comprobar(not nivel.jugador_local().congelado, "vuelves a moverte")
	nivel.free()


func test_solo_aviso_viejo_no_pisa_el_mapa_repetido() -> void:
	var nivel := _nivel_solo()
	var antes: int = nivel.semilla_actual
	var viejo: int = nivel._serial_mapa  # el que lleva el aviso de 3 s
	nivel.reiniciar()  # R
	nivel._mapa_nuevo_si_vigente(viejo)
	comprobar(nivel.semilla_actual == antes and nivel.ronda == 1, "el aviso viejo no cambia el mapa")
	nivel._mapa_nuevo_si_vigente(nivel._serial_mapa)
	comprobar(nivel.semilla_actual != antes and nivel.ronda == 2, "el aviso vigente sí")
	nivel.free()


func test_mapa_nuevo_nunca_repite_forma() -> void:
	var nivel := _nivel_solo()
	for i in 8:
		var antes := Generador.forma_de(nivel.semilla_actual)
		nivel._mapa_nuevo_solo()
		comprobar(Generador.forma_de(nivel.semilla_actual) != antes, "vuelta %d: otra vez %s" % [i, antes])
	nivel.free()


func test_choque_rapido_en_el_fondo_del_pozo_manda_al_control() -> void:
	var nivel := _nivel_construido(_semilla_de("pozo"))
	var j: Jugador = nivel.jugador_local()
	comprobar(nivel._choque_en_pozo(Generador.ESTRELLON + 100.0, j, "FondoPozo7"), "rápido en el fondo: te estrellas")
	comprobar(not nivel._choque_en_pozo(Generador.ESTRELLON - 200.0, j, "FondoPozo7"), "frenando antes: se pasa")
	comprobar(not nivel._choque_en_pozo(Generador.ESTRELLON + 100.0, j, "Descanso3"), "solo el fondo estrella, no un descanso")
	nivel.free()
