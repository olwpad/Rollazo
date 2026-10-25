# Anfitrión de la prueba de red: crea la partida y espera a un cliente (lo lanza run_tests.sh).
extends SceneTree

const PUERTO := 7791
var red: Node
var espera := 0.0
var fallos: Array[String] = []


func _process(delta: float) -> bool:
	if red == null:  # el autoload entra en el árbol después de _initialize
		red = root.get_node_or_null("Red")
		if red == null or red.crear_partida(PUERTO) != OK:
			print("sim_red: FALLO no se pudo crear la partida")
			quit(1)
		return false
	espera += delta
	if red != null and red.ids.size() == 2:
		print("sim_red: OK")
		red.salir()
		quit(0)
	elif espera > 10.0:
		print("sim_red: FALLO ningún cliente en 10 s (ids=%s)" % [red.ids])
		quit(1)
	return false
