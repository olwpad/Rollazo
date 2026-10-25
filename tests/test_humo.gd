extends Caso


func test_humo() -> void:
	comprobar(1 + 1 == 2, "la aritmética funciona")


func test_acciones_de_input_existen() -> void:
	for accion in ["lanzar", "encoger", "alargar", "izquierda", "derecha", "reiniciar", "saltar"]:
		comprobar(InputMap.has_action(accion) and InputMap.action_get_events(accion).size() == 1, accion)
