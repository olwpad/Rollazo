# Cliente de la prueba de red: se une, espera la carrera, comprueba lo que ve y se va.
extends SceneTree

var espera := 0.0
var t_carrera := -1.0
var x_inicial := INF
var x_max := -INF
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
	var mio: Node2D = jugadores.get_node_or_null(str(root.get_node("Red").multiplayer.get_unique_id())) if jugadores else null
	# Tras la postal (2,5 s quietos), mantiene D (derecha; a la izquierda está el moco del anfitrión)
	# 0.6 s: el anfitrión debe mover este moco y el Sync traer la posición.
	if mio != null and t_carrera >= 0.0 and x_inicial == INF and espera - t_carrera > 3.0:
		x_inicial = mio.global_position.x
		Input.action_press("derecha")
	if x_inicial != INF and mio != null:
		x_max = maxf(x_max, mio.global_position.x)
	if x_inicial != INF and espera - t_carrera > 3.6:
		Input.action_release("derecha")
	if t_carrera >= 0.0 and espera - t_carrera > 4.5:
		if not "RONDA 1 DE 5" in current_scene.hud.get_node("Postal").titulo:
			fallos.append("el cliente no vio la postal de la ronda 1")
		if x_max < x_inicial + 80.0:
			fallos.append("mi moco no se movió a la derecha (x %.0f, máximo %.0f)" % [x_inicial, x_max])
		if jugadores == null or jugadores.get_child_count() != 2:
			fallos.append("el cliente no ve 2 mocos")
		if root.get_node("Red").ids.size() != 2:
			fallos.append("el cliente no recibió la lista de jugadores (%s)" % [root.get_node("Red").ids])
		var camaras := current_scene.find_children("*", "Camera2D", true, false)
		if camaras.size() != 1 or camaras[0].get_parent().name != str(root.get_node("Red").multiplayer.get_unique_id()):
			fallos.append("el cliente debe tener 1 cámara, la de su moco")
		var mapa := Generador.generar(123)  # piezas + burbujas de poder (vienen activadas por defecto) + sierras
		var hechas := current_scene.get_node("Piezas")  # los temas vivos también cuelgan aquí: se mira pieza a pieza, no el total
		var faltan: Array = mapa.piezas.filter(func(p: Dictionary) -> bool: return not p.nombre.begins_with("SueloSalida") and hechas.get_node_or_null(NodePath(p.nombre)) == null)
		if not faltan.is_empty():
			fallos.append("el cliente no construyó el mapa de la semilla del anfitrión")
		_fin()
	elif espera > 12.0:
		fallos.append("la carrera no empezó en el cliente")
		_fin()
	return false


func _fin() -> void:
	print("sim_red_cliente: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
	quit(0 if fallos.is_empty() else 1)
