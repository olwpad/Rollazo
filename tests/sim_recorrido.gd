# Simulación: caer reaparece en el último control, la meta para el tiempo, R reinicia.
extends SceneTree

var nivel: Node
var j: Jugador
var frame := 0
var fallos: Array[String] = []


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 1:  # en el primer frame: así el autoload Red ya existe
		nivel = load("res://scenes/recorrido_prueba.tscn").instantiate()
		root.add_child(nivel)
		j = nivel.get_node_or_null("Jugadores/1")
		if j == null:
			print("sim_recorrido: FALLO no se creó el jugador 1")
			quit(1)
		return false
	var inicio: Vector2 = nivel.get_node("Inicio").global_position
	var control: Area2D = nivel.get_node("Controles").get_child(0)
	if frame == 10:
		j.global_position = control.global_position  # pasa por el punto de control
	elif frame == 20:
		j.global_position = nivel.get_node("Caida").global_position  # cae al vacío
	elif frame == 30:
		_comprobar(j.global_position.distance_to(control.global_position) < 80, "reaparece en el control")
		_comprobar(nivel.corriendo, "el tiempo corre")
		j.global_position = nivel.get_node("Meta").global_position
	elif frame == 40:
		_comprobar(not nivel.corriendo, "la meta para el tiempo")
		_comprobar(nivel.mejor < INF, "guarda el mejor tiempo")
		_comprobar("PUESTO 1" in nivel.hud.mensaje.text, "el HUD muestra el puesto")
		var otro: Jugador = load("res://scenes/jugador.tscn").instantiate()
		otro.name = "2"
		nivel.get_node("Jugadores").add_child(otro)
		nivel.reiniciar()
	elif frame == 42:
		_comprobar(nivel.corriendo and nivel.tiempo < 0.1, "R reinicia el tiempo")
		_comprobar(j.global_position.distance_to(inicio) < 80, "R vuelve al inicio")
		var otro: Node2D = nivel.get_node("Jugadores/2")
		_comprobar(absf(otro.global_position.x - j.global_position.x) >= 40.0, "cada moco reaparece en su sitio, no apilados")
		print("sim_recorrido: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false


func _comprobar(c: bool, m: String) -> void:
	if not c:
		fallos.append(m)
