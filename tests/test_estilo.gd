extends Caso


func test_pose_colgado() -> void:
	comprobar(Jugador.elegir_pose(false, true, Vector2(300, 100)) == "rope", "enganchado = rope")


func test_pose_quieto_y_andando() -> void:
	comprobar(Jugador.elegir_pose(true, false, Vector2(5, 0)) == "idle", "quieto = idle")
	comprobar(Jugador.elegir_pose(true, false, Vector2(200, 0)) == "walk", "andando = walk")


func test_pose_aire() -> void:
	comprobar(Jugador.elegir_pose(false, false, Vector2(0, -300)) == "jump", "subiendo = jump")
	comprobar(Jugador.elegir_pose(false, false, Vector2(0, 300)) == "fall", "bajando = fall")


func test_todas_las_poses_existen() -> void:
	for personaje in ["hombre", "mujer", "aventurero", "aventurera", "zombi", "robot"]:
		for pose in ["rope", "idle", "jump", "fall", "walk0", "walk7"]:
			var ruta := "res://assets/personajes/%s/%s.png" % [personaje, pose]
			comprobar(ResourceLoader.exists(ruta), ruta)


func test_onomatopeya() -> void:
	var o: Label = Onomatopeya.crear("¡FWIP!", Vector2(10, 20))
	comprobar(o.text == "¡FWIP!", "texto")
	comprobar(o.position.distance_to(Vector2(10, 20)) < 200, "aparece cerca")
	o.free()


func test_escenas_con_estilo() -> void:
	var j: Node = load("res://scenes/jugador.tscn").instantiate()
	comprobar(j.get_node_or_null("Visual/Pose") is Sprite2D, "jugador con Sprite2D Pose")
	comprobar(j.get_node_or_null("EfectosComic") != null, "jugador con EfectosComic")
	j.free()
	var r: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	comprobar(r.get_node_or_null("Fondo") is Polygon2D, "recorrido con Fondo")
	r.free()
