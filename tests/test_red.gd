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


func test_config_por_defecto_y_listos() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7796)
	comprobar(red.config.rondas == 5, "5 rondas por defecto")
	red.ids.assign([1, 7])
	comprobar(not red.todos_listos(), "falta que el 7 diga listo")
	red.listos[7] = true
	comprobar(red.todos_listos(), "el anfitrión cuenta como listo")
	red.poner_rondas(7)
	comprobar(red.config.rondas == 7 and not red.todos_listos(), "cambiar la partida borra los listos")
	red.poner_rondas(4)
	comprobar(red.config.rondas == 7, "solo 3, 5, 7 o 10")
	red.salir()


func test_sala_marca_los_listos() -> void:
	var sala: Node2D = load("res://scripts/sala.gd").new()
	Engine.get_main_loop().root.add_child(sala)
	var ids: Array[int] = [1, 7]
	sala.mostrar(ids, 1, {7: true})
	comprobar(sala.etiqueta(1).ends_with("✓") and not sala.etiqueta(0).ends_with("✓"), "✓ solo bajo quien está listo")
	sala.free()


func test_cliente_no_toca_la_partida() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7797)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	comprobar(menu.get_node("Caja/Partida").visible, "online se ve LA PARTIDA")
	comprobar(not menu.get_node("Caja/Partida/Rondas/Menos").disabled, "el anfitrión cambia las rondas")
	comprobar(not menu.get_node("Caja/Listo").visible, "el anfitrión no necesita LISTO")
	menu.free()
	red.salir()


func test_practicar_solo_oculto_en_partida_online() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7795)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	comprobar(not menu.get_node("Caja/Solo").visible, "sin 'Practicar solo' mientras hay partida")
	comprobar(not menu.get_node("Caja/Crear").visible and not menu.get_node("Caja/Fila").visible, "ni crear otra ni unirse a otra")
	menu.free()
	red.salir()
