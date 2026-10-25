# Simulación: clicar rápido no da impulso gratis, y un clic dentro de un mismo frame no te deja colgado.
extends SceneTree

var j: Jugador
var frame := 0
var fallos: Array[String] = []


func _initialize() -> void:
	var nivel: Node = load("res://scenes/prueba_columpio.tscn").instantiate()
	j = nivel.get_node("Jugador")
	j.set_script(load("res://tests/jugador_simulado.gd"))
	j.position = Vector2(600, 520)  # en el aire, bajo el techo
	root.add_child(nivel)


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		j.velocity = Vector2(600, 0)
		j.guion = {"apunta": j.global_position + Vector2(0, -400), "lanzar": true}
	elif frame == 3:
		_comprobar(j.papel != null, "se engancha")
		j.guion = {"soltar": true}  # suelta al frame siguiente
	elif frame == 4:
		_comprobar(j.papel == null, "suelta")
		_comprobar(j.velocity.length() < 600.0 * 1.1, "clic rápido sin impulso extra (%.0f)" % j.velocity.length())
		j.guion = {"apunta": j.global_position + Vector2(0, -400), "lanzar": true, "soltar": true}
	elif frame == 5:
		_comprobar(j.papel == null, "pulsar y soltar en el mismo frame no deja colgado")
		print("sim_clics: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false


func _comprobar(c: bool, m: String) -> void:
	if not c:
		fallos.append(m)
