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
