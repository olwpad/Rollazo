# Un moco toca el borde de un aro de fuego: se quema y vuelve a la salida (o al último control), como al caer.
extends SceneTree

var nivel: Node
var yo: Node2D
var f := 0
var fallos: Array[String] = []


func _process(_d: float) -> bool:
	f += 1
	if f == 1:
		var red: Node = root.get_node("Red")
		red.config.mapas = ["cueva"]
		red.semilla = 3
		nivel = load("res://scenes/recorrido_prueba.tscn").instantiate()
		root.add_child(nivel)
	elif f == 10:
		yo = nivel.get_node("Jugadores/1")
		var aro: Node2D = nivel.get_node("Piezas").find_children("Aro*", "", false, false)[0]
		yo.global_position = aro.global_position + Vector2(-120, 82)  # va directo al borde de abajo
		yo.velocity = Vector2(600, 0)
	elif f == 60:
		var inicio: Vector2 = nivel.get_node("Inicio").global_position
		if yo.global_position.distance_to(inicio) > 300.0:
			fallos.append("no volvió a la salida (está en %s)" % yo.global_position)
		if yo.get_node("Visual").modulate.r > 0.95:
			fallos.append("no se le ve chamuscado")
		print("sim_aro: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false
