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
