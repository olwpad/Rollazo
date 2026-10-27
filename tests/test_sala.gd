extends Caso


func _menu() -> Node:
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	return menu


func test_sala_con_seis_huecos_y_tu_solo_sin_red() -> void:
	var menu := _menu()
	var sala = menu.get_node_or_null("Sala")
	comprobar(sala != null and sala.huecos.size() == 6, "6 huecos en la azotea")
	if sala != null:
		comprobar(sala.ocupados() == 1 and sala.etiqueta(0) == "TÚ", "sin red solo estás tú")
	menu.free()


func test_menu_con_cuatro_mocos_y_hasta_6_jugadores() -> void:
	var menu := _menu()
	var sala = menu.get_node("Sala")
	var vistos: Array = sala.huecos.filter(func(h: Dictionary) -> bool: return h.nodo.visible and h.moco.visible)
	comprobar(vistos.size() == 4, "en el menú, tu moco y 3 de adorno: %d" % vistos.size())
	comprobar(sala.etiqueta(0) == "TÚ" and sala.etiqueta(1) == "", "solo el tuyo lleva nombre")
	comprobar(sala.get_node("Capacidad").visible and sala.get_node("Capacidad").text == "HASTA 6 JUGADORES", "un único texto")
	sala.tarjetas = true
	comprobar(not sala.get_node("Capacidad").visible, "en la sala de la partida, tarjetas como antes")
	comprobar(sala.huecos.all(func(h: Dictionary) -> bool: return h.nodo.visible), "en la sala, los 6 huecos")
	menu.free()


func test_codigo_vacio_y_se_recuerda() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://ajustes.cfg")
	var antes: String = cfg.get_value("red", "ultimo_codigo", "")  # el de verdad del jugador: se repone al final
	cfg.set_value("red", "ultimo_codigo", "")
	cfg.save("user://ajustes.cfg")
	var menu := _menu()
	comprobar(menu.codigo.text == "" and menu.codigo.placeholder_text == "CÓDIGO", "vacío con texto guía")
	comprobar(menu.get_node("Caja/Fila/Unirse").disabled, "sin código, UNIRSE apagado")
	menu.codigo.text = "kap"
	menu.codigo.text_changed.emit(menu.codigo.text)
	comprobar(menu.codigo.text == "KAP" and menu.get_node("Caja/Fila/Unirse").disabled, "mayúsculas y con 3 letras sigue apagado")
	menu.codigo.text = "kapu"
	menu.codigo.text_changed.emit(menu.codigo.text)
	comprobar(not menu.get_node("Caja/Fila/Unirse").disabled, "con 4 letras se enciende")
	comprobar(not "ESC" in menu.get_node("Pie").text.to_upper(), "en el inicio Esc no hace nada: no se anuncia")
	menu._unirse()
	menu.free()
	Engine.get_main_loop().root.get_node("Red").salir()
	menu = _menu()
	comprobar(menu.codigo.text == "KAPU", "recuerda el último código")
	menu.free()
	cfg.load("user://ajustes.cfg")
	cfg.set_value("red", "ultimo_codigo", antes)
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


func test_sala_enseña_seis_jugadores() -> void:
	var sala: Node2D = load("res://scripts/sala.gd").new()
	Engine.get_main_loop().root.add_child(sala)
	sala.tarjetas = true
	var ids: Array[int] = [1, 2, 3, 4, 5, 6]
	sala.mostrar(ids, 1)
	comprobar(sala.ocupados() == 6 and sala.huecos.size() == 6, "seis ocupados")
	comprobar(sala.huecos[3].nodo.scale.x < sala.huecos[0].nodo.scale.x and sala.huecos[3].nodo.position.y < sala.huecos[0].nodo.position.y, "los de atrás, más pequeños y altos")
	sala.free()


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


# Con el vestidor abierto en el lobby llegan avisos de los demás (entra alguien, se viste, se pone
# listo): el menú no debe volver a pintar la sala ni sus botones encima del vestidor.
func test_aviso_de_red_no_tapa_el_vestidor() -> void:
	var menu := _menu()
	menu._vestir(true)
	Red.jugadores_cambiaron.emit()
	Red.config_cambiada.emit()
	for nodo in ["Caja", "Sala", "Columpio", "Pie", "Nota", "SalaUI", "Salir"]:
		comprobar(not menu.get_node(nodo).visible, nodo + " sigue escondido con el vestidor abierto")
	comprobar(menu.get_node("Vestidor").visible, "el vestidor sigue abierto")
	menu._vestir(false)
	comprobar(menu.get_node("Caja").visible and menu.get_node("Sala").visible, "al cerrar vuelve el menú")
	menu.free()
