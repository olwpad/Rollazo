# Simulación: Espacio salta desde el suelo, pero no en el aire.
extends SceneTree

var j: Jugador
var frame := 0
var fallos: Array[String] = []
var y_suelo := 0.0


func _initialize() -> void:
	var nivel: Node = load("res://scenes/prueba_columpio.tscn").instantiate()
	j = nivel.get_node("Jugador")
	j.set_script(load("res://tests/jugador_simulado.gd"))
	root.add_child(nivel)


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 30:
		_comprobar(j.is_on_floor(), "en el suelo")
		y_suelo = j.global_position.y
		j.guion = {"saltar": true}
	elif frame == 40:
		_comprobar(j.global_position.y < y_suelo - 40, "salta")
		j.guion = {"saltar": true}
	elif frame == 41:
		_comprobar(j.velocity.y > -600.0, "no hay doble salto en el aire")
		print("sim_salto: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false


func _comprobar(c: bool, m: String) -> void:
	if not c:
		fallos.append(m)
