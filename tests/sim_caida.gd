# Caída fuera de la franja: un moco que se pasa la meta por encima y cae más allá vuelve a su
# control (solo); si ya había llegado (online), pasa a mirar.
extends SceneTree

const PUERTO := 7795
var nivel: Node
var yo: Node2D
var control := Vector2.ZERO
var f := 0
var fallos: Array[String] = []


func _process(_d: float) -> bool:
	f += 1
	var red: Node = root.get_node("Red")
	if f == 1:
		red.semilla = 7
		nivel = load("res://scenes/recorrido_prueba.tscn").instantiate()
		root.add_child(nivel)
	elif f == 10:
		yo = nivel.get_node("Jugadores/1")
		control = nivel.get_node("Controles").get_child(0).global_position
		nivel.ultimos_controles["1"] = control
		var l: Rect2 = nivel.limites
		yo.global_position = Vector2(nivel.get_node("Meta").position.x + 3000.0, l.end.y + 1000.0)
	elif f == 20:
		if yo.global_position.distance_to(control) > 150.0:
			fallos.append("solo: no volvió al último control (está en %s)" % yo.global_position)
		nivel.free()
		if red.crear_partida(PUERTO) != OK:
			fallos.append("no se pudo crear la partida")
		nivel = load("res://scenes/recorrido_prueba.tscn").instantiate()
		root.add_child(nivel)
	elif f == 30:
		yo = nivel.get_node("Jugadores/1")
		nivel.clasificacion.llegadas.append(1)
		var l: Rect2 = nivel.limites
		yo.global_position = Vector2(l.end.x + 2000.0, nivel.get_node("Meta").position.y - 200.0)  # a la altura de la meta: la otra regla no lo cogería
	elif f == 40:
		if not 1 in nivel.espectadores:
			fallos.append("online: el que ya llegó no pasó a espectador")
		red.salir()
		print("sim_caida: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false
