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
		comprobar(sala.etiqueta(2) == "ESPERANDO…", "hueco libre")
	menu.free()
