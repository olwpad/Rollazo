# Sierra: tocarla devuelve el moco a la salida (o al último control), como al caer; la del riel se mueve con el reloj de la ronda.
extends SceneTree

var nivel: Node
var yo: Node2D
var sierra: Sierra
var f := 0
var fallos: Array[String] = []


func _process(_d: float) -> bool:
	f += 1
	if f == 1:
		var red: Node = root.get_node("Red")
		red.semilla = 6  # sale bajada, con sierras
		nivel = load("res://scenes/recorrido_prueba.tscn").instantiate()
		root.add_child(nivel)
	elif f == 10:
		yo = nivel.get_node("Jugadores/1")
		sierra = nivel.get_node("Piezas").find_children("Sierra*", "", false, false)[0]
		var donde: Vector2 = sierra._base + sierra.posicion_en(nivel.reloj_ronda)
		if not sierra.position.is_equal_approx(donde):
			fallos.append("la sierra no sigue el reloj de la ronda")
		yo.global_position = sierra.global_position + Vector2(-120, 0)
		yo.velocity = Vector2(900, 0)
	elif f == 60:
		var inicio: Vector2 = nivel.get_node("Inicio").global_position
		if yo.global_position.distance_to(inicio) > 300.0:
			fallos.append("tocando la sierra no volvió a la salida (está en %s)" % yo.global_position)
		print("sim_sierra: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false
