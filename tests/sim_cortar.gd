# Simulación: un moco corta el papel de otro; y dos que se cortan en el mismo frame.
extends SceneTree

var nivel: Node
var j1: Jugador
var j2: Jugador
var j3: Jugador
var j4: Jugador
var frame := 0
var fallos: Array[String] = []


func _initialize() -> void:
	nivel = load("res://scenes/prueba_columpio.tscn").instantiate()
	j1 = nivel.get_node("Jugador")
	j1.set_script(load("res://tests/jugador_simulado.gd"))
	j2 = _nuevo("2")
	j3 = _nuevo("3")
	j4 = _nuevo("4")
	root.add_child(nivel)


func _nuevo(nombre: String) -> Jugador:
	var j: Jugador = load("res://scenes/jugador.tscn").instantiate()
	j.name = nombre
	j.set_script(load("res://tests/jugador_simulado.gd"))
	nivel.add_child(j)
	return j


func _colgar(j: Jugador, pos: Vector2) -> void:
	j.global_position = pos
	j.velocity = Vector2.ZERO
	j.papel = PapelRope.new(Vector2(pos.x, 320), pos.y - 320, 3.0)


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		_colgar(j2, Vector2(400, 500))
		j1.global_position = Vector2(445, 420)  # a 45 px del papel del 2
		_colgar(j3, Vector2(900, 500))
		_colgar(j4, Vector2(945, 500))  # cada uno cerca del papel del otro
	elif frame == 2:
		j1.guion = {"cortar": true}
		j3.guion = {"cortar": true}
		j4.guion = {"cortar": true}
	elif frame == 4:
		_comprobar(j2.papel == null, "el 1 corta el papel del 2")
		_comprobar(j3.papel == null and j4.papel == null, "corte mutuo en el mismo frame")
		print("sim_cortar: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false


func _comprobar(c: bool, m: String) -> void:
	if not c:
		fallos.append(m)
