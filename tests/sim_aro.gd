# Aro de fuego: por el centro se pasa sin quemarse; tocar el borde quema y devuelve a la salida (o al último control), como al caer.
extends SceneTree

var nivel: Node
var yo: Node2D
var aro: Node2D
var f := 0
var fallos: Array[String] = []


func _process(_d: float) -> bool:
	f += 1
	if f == 1:
		var red: Node = root.get_node("Red")
		red.config.mapas = ["cueva"]
		red.config.aros = true  # por defecto van quitados
		red.semilla = 3
		nivel = load("res://scenes/recorrido_prueba.tscn").instantiate()
		root.add_child(nivel)
	elif f == 10:
		yo = nivel.get_node("Jugadores/1")
		aro = nivel.get_node("Piezas").find_children("Aro*", "", false, false)[0]
		aro.mov = "quieto"  # que no se mueva mientras probamos
		aro.position = aro._base
		yo.global_position = aro.global_position + Vector2(-140, 0)  # directo al centro
		yo.velocity = Vector2(1400, 0)
	elif f == 40:
		if yo.global_position.x < aro.global_position.x + 60.0:
			fallos.append("no cruzó el aro por el centro (está en %s)" % yo.global_position)
		if yo.get_node("Visual").modulate.r < 0.95:
			fallos.append("se quemó pasando por el centro")
		yo.global_position = aro.global_position + Vector2(-140, aro.RY)  # ahora al borde de abajo
		yo.velocity = Vector2(700, 0)
	elif f == 90:
		var inicio: Vector2 = nivel.get_node("Inicio").global_position
		if yo.global_position.distance_to(inicio) > 300.0:
			fallos.append("tocando el borde no volvió a la salida (está en %s)" % yo.global_position)
		if yo.get_node("Visual").modulate.r > 0.95:
			fallos.append("no se le ve chamuscado")
		print("sim_aro: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false
