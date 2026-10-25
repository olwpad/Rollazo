# Cliente de la prueba de red: se une, espera la carrera, comprueba lo que ve y se va.
extends SceneTree

var espera := 0.0
var t_carrera := -1.0
var unido := false
var fallos: Array[String] = []


func _process(delta: float) -> bool:
	if not unido:  # el autoload entra en el árbol después de _initialize
		unido = true
		root.get_node("Red").unirse("127.0.0.1", 7791)
	espera += delta
	var jugadores := current_scene.get_node_or_null("Jugadores") if current_scene else null
	if t_carrera < 0.0 and jugadores != null:
		t_carrera = espera
	if t_carrera >= 0.0 and espera - t_carrera > 2.0:
		if jugadores == null or jugadores.get_child_count() != 2:
			fallos.append("el cliente no ve 2 mocos")
		var camaras := current_scene.find_children("*", "Camera2D", true, false)
		if camaras.size() != 1 or camaras[0].get_parent().name != str(root.get_node("Red").multiplayer.get_unique_id()):
			fallos.append("el cliente debe tener 1 cámara, la de su moco")
		_fin()
	elif espera > 12.0:
		fallos.append("la carrera no empezó en el cliente")
		_fin()
	return false


func _fin() -> void:
	print("sim_red_cliente: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
	quit(0 if fallos.is_empty() else 1)
