extends Caso


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


func test_caben_cuatro_mocos_en_la_salida() -> void:
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	var suelo: Node2D = nivel.get_node("SueloInicio")
	var borde: float = suelo.position.x + suelo.get_node("Forma").shape.size.x / 2.0
	var ultimo: float = nivel.get_node("Inicio").position.x + 3 * 90.0
	comprobar(ultimo + 25.0 < borde, "el 4.º moco (x=%.0f) sale encima del suelo (borde %.0f)" % [ultimo, borde])
	nivel.free()


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


func test_caben_cuatro_mocos_en_la_salida_de_una_bajada() -> void:
	var nivel := _nivel_construido(_semilla_de("bajada"))
	var suelo: Node2D = nivel.get_node("SueloInicio")
	var borde: float = suelo.position.x + suelo.get_node("Forma").shape.size.x / 2.0
	var inicio: Vector2 = nivel.get_node("Inicio").position
	comprobar(inicio.x + 3 * 90.0 + 25.0 < borde, "el 4.º moco sale encima del suelo de la bajada")
	comprobar(suelo.position.y > inicio.y, "el suelo está debajo de la salida")
	nivel.free()


func test_meta_y_caida_no_se_contagian_entre_niveles() -> void:
	var nivel := _nivel_construido(_semilla_de("torre"))
	var limpio: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	comprobar(limpio.get_node("Meta/Forma").shape.size.y >= 1200.0, "una torre no encoge la meta de otro nivel")
	limpio.free()
	nivel.free()
