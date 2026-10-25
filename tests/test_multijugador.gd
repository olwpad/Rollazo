extends Caso


func test_colores_distintos() -> void:
	var c: Array = Jugador.COLORES
	comprobar(c.size() == 4, "4 colores")
	for i in c.size():
		for k in range(i + 1, c.size()):
			comprobar(c[i] != c[k], "colores %d y %d distintos" % [i, k])


func test_jugador_tiene_sincronizador() -> void:
	var j: Node = load("res://scenes/jugador.tscn").instantiate()
	comprobar(j.get_node_or_null("Sync") is MultiplayerSynchronizer, "jugador con Sync")
	j.free()


func test_recorrido_tiene_spawner() -> void:
	var r: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	comprobar(r.get_node_or_null("Jugadores") != null, "nodo Jugadores")
	comprobar(r.get_node_or_null("Spawner") is MultiplayerSpawner, "MultiplayerSpawner")
	comprobar(r.get_node_or_null("Jugador") == null, "sin jugador fijo")
	r.free()
