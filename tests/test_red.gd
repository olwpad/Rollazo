extends Caso


func test_constantes_de_red() -> void:
	var red: GDScript = load("res://scripts/red.gd")
	comprobar(red != null and red.PUERTO == 7777, "puerto 7777")
	comprobar(red != null and red.MAX_JUGADORES == 4, "máximo 4 jugadores")


func test_red_es_autoload() -> void:
	comprobar(ProjectSettings.get_setting("autoload/Red", "") == "*res://scripts/red.gd", "autoload Red")


func test_menu_es_la_escena_principal() -> void:
	comprobar(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/menu.tscn", "main_scene = menu")


func test_menu_muestra_por_que_volviste() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.ultimo_motivo = "El anfitrión se ha ido"
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	comprobar(menu.estado.text == "El anfitrión se ha ido", "el menú nuevo enseña el motivo")
	comprobar(red.ultimo_motivo == "", "el motivo se enseña una sola vez")
	menu.free()


func test_practicar_solo_oculto_en_partida_online() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7795)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	comprobar(not menu.get_node("Caja/Solo").visible, "sin 'Practicar solo' mientras hay partida")
	comprobar(not menu.get_node("Caja/Crear").visible and not menu.get_node("Caja/Fila").visible, "ni crear otra ni unirse a otra")
	menu.free()
	red.salir()
