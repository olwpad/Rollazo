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


func test_elige_la_ip_de_tailscale() -> void:
	var red: GDScript = load("res://scripts/red.gd")
	comprobar(red.elegir_ip(PackedStringArray(["127.0.0.1", "fe80::1", "192.168.1.5", "100.64.0.7"])) == "100.64.0.7", "la de Tailscale primero")
	comprobar(red.elegir_ip(PackedStringArray(["127.0.0.1", "192.168.1.5"])) == "192.168.1.5", "si no, la de la red de casa")


func test_sala_del_anfitrion() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7797)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	comprobar(menu.get_node("SalaUI").visible and not menu.get_node("Caja").visible, "en la sala no queda el menú de antes")
	comprobar(menu.get_node("SalaUI/Notita/Caja/Resumen").text == "5 RONDAS · 5 MAPAS\nCON PODERES","resumen de la partida")
	comprobar(menu.get_node("SalaUI/Notita/Caja/Cambiar").visible, "el anfitrión puede cambiarla")
	menu.get_node("SalaUI/Notita/Caja/Cambiar").pressed.emit()
	comprobar(menu.get_node("Config").visible, "CAMBIAR abre la pantalla de postales")
	menu.get_node("Config/Papel/Caja/Pegatinas/Rondas").pressed.emit()
	comprobar(red.config.rondas == 7 and menu.get_node("SalaUI/Notita/Caja/Resumen").text.begins_with("7 RONDAS"), "la pegatina pasa de 5 a 7 rondas")
	comprobar(menu.get_node("Config/Papel/Caja/Pegatinas/Rondas").text == "7", "la pegatina enseña el número")
	var postales := menu.get_node("Config/Papel/Caja/Mapas").get_children().filter(func(n: Node) -> bool: return n is Postal)
	comprobar(postales.size() == 5, "una postal por mapa")
	var clic := InputEventMouseButton.new()
	clic.pressed = true
	clic.button_index = MOUSE_BUTTON_LEFT
	menu.get_node("Config/Papel/Caja/Mapas/cueva").gui_input.emit(clic)
	comprobar(not "cueva" in red.config.mapas and menu.get_node("Config/Papel/Caja/Mapas/cueva").apagada, "tocar una postal quita ese mapa")
	menu.get_node("Config/Papel/Caja/Mapas/Todos").pressed.emit()
	comprobar(red.config.mapas.size() == 5, "TODOS vuelve a poner los 5")
	comprobar(not menu.get_node("Config/Papel/Caja/Pegatinas/Aros").visible and not "AROS" in menu.get_node("SalaUI/Notita/Caja/Resumen").text, "los aros, de momento, ni se ofrecen")
	comprobar(menu.get_node("SalaUI/Principal").text.begins_with("¡A CORRER!"), "botón principal del anfitrión")
	menu.free()
	red.salir()


# El anfitrión cuenta como listo y debajo del botón se dice quién falta.
func test_contador_de_listos_y_quien_falta() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7795)
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	red.ids.assign([1, 5, 6])
	red.listos[5] = true
	menu._actualizar()
	comprobar(menu.get_node("SalaUI/Principal").text == "¡A CORRER! · 2/3 LISTOS", "cuenta al anfitrión: " + menu.get_node("SalaUI/Principal").text)
	comprobar(menu.get_node("SalaUI/Estado").text == "FALTA: JUGADOR 3", "quién falta: " + menu.get_node("SalaUI/Estado").text)
	menu.get_node("SalaUI/Ip/Fila/Copiar").pressed.emit()
	comprobar(menu.get_node("SalaUI/Ip/Fila/Copiar").text == "¡COPIADA!", "copiar avisa")
	menu.free()
	red.salir()


func test_boton_para_salir_de_la_sala() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	comprobar(not menu.get_node("Salir").visible, "sin partida no hay nada de lo que salir")
	red.crear_partida(7798)
	menu._actualizar()
	comprobar(menu.get_node("Salir").visible, "en la sala se puede volver atrás")
	menu.get_node("Salir").pressed.emit()
	comprobar(not red.es_online() and menu.get_node("Caja/Crear").visible, "vuelve al menú de antes")
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
