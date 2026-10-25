# Anfitrión de la prueba de red (lo lanza run_tests.sh junto a sim_red_cliente.gd):
# espera al cliente, empieza la carrera, comprueba los 2 mocos y que el del cliente desaparece al irse.
extends SceneTree

const PUERTO := 7791
var red: Node
var espera := 0.0
var t_carrera := -1.0
var id_cliente := 0
var vistos_dos := false
var x_cliente_inicial := INF
var x_cliente_min := INF
var t_salida := -1.0
var fallos: Array[String] = []


func _process(delta: float) -> bool:
	if red == null:  # el autoload entra en el árbol después de _initialize
		red = root.get_node_or_null("Red")
		if red == null or red.crear_partida(PUERTO) != OK:
			_fin("no se pudo crear la partida")
		return false
	espera += delta
	if t_carrera < 0.0:
		if red.ids.size() == 2:
			id_cliente = red.ids[1]
			red.empezar_carrera.rpc()
			t_carrera = espera
		elif espera > 10.0:
			_fin("ningún cliente en 10 s")
		return false
	var jugadores := current_scene.get_node_or_null("Jugadores") if current_scene else null
	if not vistos_dos and espera - t_carrera > 1.5:
		vistos_dos = true
		if jugadores == null or jugadores.get_node_or_null("1") == null or jugadores.get_node_or_null(str(id_cliente)) == null:
			fallos.append("el anfitrión no ve los 2 mocos")
		else:  # el anfitrión llega a la meta; falta el cliente
			jugadores.get_node("1").global_position = current_scene.get_node("Meta").global_position
	var cliente: Node2D = jugadores.get_node_or_null(str(id_cliente)) if jugadores else null
	if cliente != null:
		if x_cliente_inicial == INF:
			x_cliente_inicial = cliente.global_position.x
		x_cliente_min = minf(x_cliente_min, cliente.global_position.x)
	if vistos_dos and jugadores != null and cliente == null:
		if t_salida < 0.0:
			t_salida = espera
			if x_cliente_min > x_cliente_inicial - 100.0:
				fallos.append("el anfitrión no movió el moco del cliente con su entrada")
		if current_scene.hud.tabla.get_child_count() == 1:
			_fin("")  # el cliente se fue, su moco desapareció y la ronda terminó con 1 fila
		elif espera - t_salida > 2.0:
			_fin("la ronda no termina cuando se va el único que faltaba")
	elif espera - t_carrera > 8.0:
		_fin("el moco del cliente no desaparece al irse")
	return false


func _fin(error: String) -> void:
	if error != "":
		fallos.append(error)
	print("sim_red: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
	quit(0 if fallos.is_empty() else 1)
