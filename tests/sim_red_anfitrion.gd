# Anfitrión de la prueba de red (lo lanza run_tests.sh junto a sim_red_cliente.gd):
# espera al cliente, empieza la carrera, comprueba los 2 mocos y que el del cliente desaparece al irse.
extends SceneTree

const PUERTO := 7791
var red: Node
var espera := 0.0
var t_carrera := -1.0
var id_cliente := 0
var vistos_dos := false
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
	if vistos_dos and jugadores != null and jugadores.get_node_or_null(str(id_cliente)) == null:
		_fin("")  # el cliente se fue y su moco desapareció
	elif espera - t_carrera > 8.0:
		_fin("el moco del cliente no desaparece al irse")
	return false


func _fin(error: String) -> void:
	if error != "":
		fallos.append(error)
	print("sim_red: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
	quit(0 if fallos.is_empty() else 1)
