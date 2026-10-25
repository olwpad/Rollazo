extends Caso


func _nivel() -> Node:
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	return nivel


func test_hace_falta_que_otro_acepte() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7794)
	red.ids.assign([1, 7, 8])
	var nivel := _nivel()
	var pausa: Node = nivel.get_node("Pausa")
	pausa.pedir_de(7)
	comprobar(not nivel.get_tree().paused and pausa.pendiente == 7, "pedirla sola no pausa")
	pausa.pedir_de(7)
	comprobar(not nivel.get_tree().paused, "pedirla dos veces tampoco")
	pausa.pedir_de(8)
	comprobar(nivel.get_tree().paused, "cuando otro acepta, se pausa")
	pausa.pedir_de(99)
	comprobar(nivel.get_tree().paused, "alguien que no está en la partida no hace nada")
	nivel.free()
	comprobar(not Engine.get_main_loop().paused, "al salir del nivel nunca queda pausado")
	red.salir()


func test_sin_red_pausa_al_momento() -> void:
	var nivel := _nivel()
	nivel.get_node("Pausa").alternar_local()
	comprobar(nivel.get_tree().paused, "practicando, P pausa directamente")
	nivel.free()
	comprobar(not Engine.get_main_loop().paused, "sin pausa colgada")


func test_hay_tecla_de_pausa() -> void:
	comprobar(InputMap.has_action("pausa"), "acción pausa (P)")
