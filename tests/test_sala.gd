extends Caso


func _menu() -> Node:
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	return menu


func test_sala_con_cuatro_huecos_y_tu_solo_sin_red() -> void:
	var menu := _menu()
	var sala = menu.get_node_or_null("Sala")
	comprobar(sala != null and sala.huecos.size() == 4, "4 huecos en la azotea")
	if sala != null:
		comprobar(sala.ocupados() == 1 and sala.etiqueta(0) == "TÚ", "sin red solo estás tú")
	menu.free()


func test_menu_con_cuatro_mocos_y_hasta_4_jugadores() -> void:
	var menu := _menu()
	var sala = menu.get_node("Sala")
	comprobar(sala.huecos.all(func(h: Dictionary) -> bool: return h.moco.visible), "los 4 mocos en la azotea, de adorno")
	comprobar(sala.etiqueta(0) == "TÚ" and sala.etiqueta(1) == "", "solo el tuyo lleva nombre")
	comprobar(sala.get_node("Capacidad").visible and sala.get_node("Capacidad").text == "HASTA 4 JUGADORES", "un único texto")
	sala.tarjetas = true
	comprobar(not sala.get_node("Capacidad").visible, "en la sala de la partida, tarjetas como antes")
	menu.free()


func test_ip_vacia_y_se_recuerda() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://ajustes.cfg")
	var antes: String = cfg.get_value("red", "ultima_ip", "")  # la de verdad del jugador: se repone al final
	cfg.set_value("red", "ultima_ip", "")
	cfg.save("user://ajustes.cfg")
	var menu := _menu()
	comprobar(menu.ip.text == "" and menu.ip.placeholder_text == "IP del anfitrión (100.x.x.x)", "vacía con texto guía")
	comprobar(menu.get_node("Caja/Fila/Unirse").disabled, "sin IP, UNIRSE apagado")
	menu.ip.text = "100.1.2.3"
	menu.ip.text_changed.emit(menu.ip.text)
	comprobar(not menu.get_node("Caja/Fila/Unirse").disabled, "con IP se enciende")
	comprobar(menu.get_node("Pie").text == "M MÚSICA", "en el inicio Esc no hace nada: no se anuncia")
	menu._unirse()
	menu.free()
	Engine.get_main_loop().root.get_node("Red").salir()
	menu = _menu()
	comprobar(menu.ip.text == "100.1.2.3", "recuerda la última IP")
	menu.free()
	cfg.load("user://ajustes.cfg")
	cfg.set_value("red", "ultima_ip", antes)
	cfg.save("user://ajustes.cfg")


func test_mostrar_jugadores_que_entran() -> void:
	var menu := _menu()
	var sala = menu.get_node_or_null("Sala")
	if sala == null:
		comprobar(false, "falta la sala")
	else:
		var ids: Array[int] = [1, 7]
		sala.mostrar(ids, 7)
		comprobar(sala.ocupados() == 2, "dos mocos")
		comprobar(sala.etiqueta(1) == "TÚ" and sala.etiqueta(0) == "JUGADOR 1", "tú y el anfitrión")
		comprobar(sala.etiqueta(2) == "", "en el menú los huecos libres no dicen nada")
	menu.free()


func test_en_partida_son_tarjetas() -> void:
	var sala: Node2D = load("res://scripts/sala.gd").new()
	Engine.get_main_loop().root.add_child(sala)
	sala.tarjetas = true
	var ids: Array[int] = [1, 7, 8]
	sala.mostrar(ids, 1, {7: true})
	comprobar(sala.etiqueta(3) == "HUECO LIBRE", "hueco libre en tarjeta")
	comprobar(sala.estado(0) == "LISTO · ANFITRIÓN" and sala.estado(2) == "PENSÁNDOSELO…", "estado de cada uno")
	comprobar(sala.sello_visible(1) and sala.estado(1) == "", "el listo lleva sello en vez de texto")
	sala.free()
