# Simulación: un moco lanzado contra otro en el aire lo empuja y rebota.
extends SceneTree

var j1: Jugador
var j2: Jugador
var frame := 0
var fallos: Array[String] = []
var rebotó := false


func _initialize() -> void:
	var nivel: Node = load("res://scenes/prueba_columpio.tscn").instantiate()
	j1 = nivel.get_node("Jugador")
	j1.set_script(load("res://tests/jugador_simulado.gd"))
	j2 = load("res://scenes/jugador.tscn").instantiate()
	j2.name = "2"
	j2.set_script(load("res://tests/jugador_simulado.gd"))
	nivel.add_child(j2)
	j1.position = Vector2(300, 480)
	j2.position = Vector2(370, 480)
	root.add_child(nivel)


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		j1.velocity = Vector2(600, 0)
	if j1.velocity.x <= 0.0:
		rebotó = true
	if frame == 16:
		_comprobar(j2.global_position.x > 370.0 + 60.0, "el golpeado sale empujado (x=%.0f)" % j2.global_position.x)
		_comprobar(rebotó, "el que golpea se frena en seco")
		print("sim_choque: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false


func _comprobar(c: bool, m: String) -> void:
	if not c:
		fallos.append(m)
