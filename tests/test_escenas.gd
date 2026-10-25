extends Caso


func test_jugador_se_instancia() -> void:
	var j: Node = load("res://scenes/jugador.tscn").instantiate()
	comprobar(j is Jugador, "la raíz es Jugador")
	comprobar(j.get_node_or_null("Rayo") is RayCast2D, "tiene Rayo")
	j.free()


func test_prueba_tiene_techo_enganchable() -> void:
	var e: PackedScene = load("res://scenes/prueba_columpio.tscn")
	comprobar(e != null, "existe la escena")
	if e == null:
		return
	var n := e.instantiate()
	comprobar(n.find_child("Techo*", true, false) != null and n.find_child("Techo*", true, false).is_in_group("enganchable"), "techo enganchable")
	n.free()
