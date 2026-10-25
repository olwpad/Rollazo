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


func test_recorrido_largo_y_con_caida_hasta_el_final() -> void:
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	var meta_x: float = nivel.get_node("Meta").position.x
	var caida: Area2D = nivel.get_node("Caida")
	var ancho: float = caida.get_node("Forma").shape.size.x
	comprobar(meta_x >= 7500.0, "el recorrido mide el doble (meta en x=%.0f)" % meta_x)
	comprobar(caida.position.x + ancho / 2.0 > meta_x + 500.0, "caer más allá de la meta también reaparece")
	comprobar(nivel.get_node("Controles").get_child_count() >= 3, "puntos de control en el tramo nuevo")
	nivel.free()
